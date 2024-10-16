//
//  LowerTransportLayer.swift
//  nRFMeshProvision
//
//  Created by Mostafa Berg on 27/02/2018.
//

import Foundation

public typealias SegmentedMessageAcknowledgeBlock = (_ ackData: Data) -> (Void)
public class LowerTransportLayer {
    var params : LowerTransportPDUParams!
    var partialIncomingPDU: [Data : Data]?
    var meshStateManager: MeshStateManager?
    var segmentedMessageAcknowledge: SegmentedMessageAcknowledgeBlock?
    var segAcknowledgeTimeout: DispatchTime?
    var segments: [Data]?
    var pendingAckWorkItem: DispatchWorkItem?

    // New static property to store the last complete message info
    private static var lastCompleteMessage: (seqZero: Data, src: Data, blockData: Data)?

    public init(withStateManager aStateManager: MeshStateManager, andSegmentedAcknowlegdeMent anAcknowledgementBlock: SegmentedMessageAcknowledgeBlock?) {
        segmentedMessageAcknowledge = anAcknowledgementBlock
        meshStateManager = aStateManager
        partialIncomingPDU = [Data : Data]()
    }

    public func append(withNetworkLayer networkLayer: NetworkLayer, withIncomingPDU aPDU: Data, ctl aCTL: Data, ttl aTTL: Data, src aSRC: Data, dst aDST: Data, IVIndex anIVIndex: Data, andSEQ aSEQ: Data, withRawAccess rawAccess: Bool = false) -> Any? {
        let dst = Data(aPDU[0...1])
        guard dst == meshStateManager?.state().unicastAddress else {
            print("lower Ignoring message not directed towards us!")
            return nil
        }
        let segmented = Data([aPDU[2] >> 7])
        let akf = Data([aPDU[2] >> 6 & 0x01])
        let aid = Data([aPDU[2] & 0x3F])
        let ctl = aCTL == Data([0x01]) ? true : false
        let isAppKey = akf == Data([0x01]) ? true : false

        if segmented == Data([0x00]) {
            //Unsegmented Message
            print("""
↘️ Lower Transport Layer unsegmented received:
  PDU:           \(aPDU.hexString())
  Raw:           \(rawAccess)
""")
            let incomingFullSegment = Data(aPDU[3..<aPDU.count])
            let upperLayer = UpperTransportLayer(withNetworkPdu: aPDU, withIncomingPDU: incomingFullSegment, ctl: ctl, akf: isAppKey, aid: aid, seq: aSEQ, src: aSRC, dst: aDST, szMIC: 0, ivIndex: anIVIndex, andMeshState: meshStateManager)
            //Return a parsed message
            return upperLayer.assembleMessage(withRawAccess: rawAccess)
        } else {
            let szMIC = Data([aPDU[3] >> 7])
            let seqZero = Data([(aPDU[3] & 0x7F) >> 2, ((aPDU[3] << 6) | (aPDU[4] >> 2))])
            let segO = Data([UInt8((aPDU[4] & 0x03) << 3) | UInt8((aPDU[5] & 0xE0) >> 5)])
            let segN = Data([aPDU[5] & 0x1F])
            let segment = Data(aPDU[6..<aPDU.count])
            let sequenceNumber = Data([aSEQ.first!, aSEQ[2] | seqZero[0], seqZero[1]])

            // Check if this is a duplicate of the last complete message
            if let lastMessage = LowerTransportLayer.lastCompleteMessage,
                lastMessage.seqZero == seqZero && lastMessage.src == aSRC {
                print("↘️ Lower Transport Layer ignoring duplicate message with seqZero: \(seqZero.hexString()) from source: \(aSRC.hexString()) but resending block ack")
                let ackData = acknowlegde(withSeqZero: lastMessage.seqZero, blockData: lastMessage.blockData, dst: lastMessage.src)
                segmentedMessageAcknowledge?(ackData)
                return nil
            }

            if partialIncomingPDU![segO] == nil {
                print("""
↘️ Lower Transport Layer segmented received:
  PDU:           \(aPDU.hexString())
  Sequence num:  \(sequenceNumber.hexString())
  SzMIC:         \(szMIC.hexString())
  SeqZero:       \(seqZero.hexString())
  SegO:          \(segO.hexString())
  SegN:          \(segN.hexString())
  Segment:       \(segment.hexString())
  Sequence:      \(aSEQ.hexString())
""")
                partialIncomingPDU![segO] = segment
            } else {
                print("↘️ Lower Transport Layer segmented duplicate \(segO.hexString()) received, dropping...")
            }
            if segmentedMessageAcknowledge != nil {
                if segAcknowledgeTimeout == nil {
                    //Send ack block after this timeout
                    segAcknowledgeTimeout = DispatchTime.now() + .milliseconds(150 + (50 * Int(aTTL[0])))
                    let workItem = DispatchWorkItem {
                        print("↗️ Lower Transport Layer sending pending ACK for \(seqZero.hexString()) because timeout")
                        //Send the pending acknowledgment after the deadline
                        self.sendPendingAcknowledgement(forSeqZero: seqZero, segmentNumber: segN, andSourceAddrsess: aSRC)
                    }

                    DispatchQueue.main.asyncAfter(deadline: segAcknowledgeTimeout!, execute: workItem)

                    // Store the work item for potential cancellation
                    self.pendingAckWorkItem = workItem
                }

                //All segments have arrived
                if Int((partialIncomingPDU?.count)! - 1) == Int(segN[0]) {
                    print("↗️ Lower Transport Layer send complete ACK for \(seqZero.hexString())")
                    //If there is a pending block acknowledgement, cancel timer and perform now.
                    sendPendingAcknowledgement(forSeqZero: seqZero, segmentNumber: segN, andSourceAddrsess: aSRC)
                    let sortedSegmentKeys = Array(partialIncomingPDU!.keys).sorted { (a, b) -> Bool in
                        return a[0] < b[0]
                    }
                    var fullData = Data()
                    for aKey in sortedSegmentKeys {
                        fullData.append(partialIncomingPDU![aKey]!)
                    }
                    partialIncomingPDU?.removeAll()

                    // Save the current message info as the last complete message
                    let blockData = createBlockData(receivedSegments: partialIncomingPDU!, segN: segN)
                    LowerTransportLayer.lastCompleteMessage = (seqZero: seqZero, src: aSRC, blockData: blockData)

                    let upperLayer = UpperTransportLayer(withNetworkPdu: aPDU, withIncomingPDU: fullData, ctl: ctl, akf: isAppKey, aid: aid, seq: sequenceNumber, src: aSRC, dst: aDST, szMIC: Int(szMIC[0]), ivIndex: anIVIndex, andMeshState: meshStateManager!)
                    return upperLayer.assembleMessage(withRawAccess: rawAccess)
                }
            }
        }
        return nil
    }

    public func sendPendingAcknowledgement(forSeqZero seqZero: Data, segmentNumber segN: Data, andSourceAddrsess aSRC: Data) {
        if let pendingAckWorkItem = self.pendingAckWorkItem {
            pendingAckWorkItem.cancel()
            self.pendingAckWorkItem = nil
        }

        if segAcknowledgeTimeout != nil {
            segAcknowledgeTimeout = nil //Reset timer
            let blockData = createBlockData(receivedSegments: partialIncomingPDU!, segN: segN)
            let ackData = acknowlegde(withSeqZero: seqZero, blockData: blockData, dst: aSRC)
            segmentedMessageAcknowledge?(ackData)
        }
    }

    public func acknowlegde(withSeqZero seqZero: Data, blockData: Data, dst: Data) -> Data {
        let aState = meshStateManager!.state()

        var payload = Data([UInt8((seqZero[0] & 0x1F) << 2) | UInt8((seqZero[1] & 0xC0) >> 6),
                            UInt8(seqZero[1] << 2)])
        payload.append(blockData)
        let opcode  = Data([0x00]) //Segment ACK Opcode
        let ackMessage = ControlMessagePDU(withPayload: payload, opcode: opcode, netKey: aState.netKeys[0].key, seq: SequenceNumber(), ivIndex: aState.netKeys[0].phase, source: aState.unicastAddress, andDst: dst)
        var ackData = Data([0x00]) //Network PDU
        let networkPDU = ackMessage.assembleNetworkPDU()!.first!
        ackData.append(Data(networkPDU))
        return Data(ackData)
    }

    private func createBlockData(receivedSegments: [Data : Data], segN: Data) -> Data {
        var block: UInt32 = 0x00000000
        for aSegmentIndex in 0...segN[0] {
            if receivedSegments[Data([aSegmentIndex])] != nil {
                block = block + UInt32((1 << aSegmentIndex))
            }
        }
        return Data(fromInt32: block)
    }

    public func handleSegmentAcknowledgmentMessage(_ ackMsg: SegmentAcknowledgmentMessage) -> [Data] {
        //lowerTransport
        print("lower layer should handle segement ack")

        var resendSegs = [Data]()
        if let segs = segments {
            if !ackMsg.areAllSegmentsReceived(lastSegmentNumber: UInt8(segs.count)) {
                for (index, segment) in segs.enumerated() {
                    if !ackMsg.isSegmentReceived(index) {
                        print("lower resending seg: \(index)")
                        resendSegs.append(segment);
                    }
                }
            }
        }
        return resendSegs;
    }

    public init(withParams someParams: LowerTransportPDUParams) {
        params = someParams
    }

    public func createPDU() -> [Data] {
        if params.ctl == Data([0x01]) {
            if isSegmented() {
                segments = createSegmentedControlMessage()
                return segments!
            } else {
                return [createUnsegmentedControlMessage()]
            }
        } else {
            if isSegmented() {
                segments = createSegmentedAccessMessage()
                return segments!
            } else {
                return [createUnsegmentedAccessMessasge()]
            }
        }
   }

    // MARK: - Segmentation
    private func createUnsegmentedAccessMessasge() -> Data {
        var lowerData = Data()
        //First octet = (1BIT)0 || (1BIT)AFK || (6BITS)AID
        var headerByte = Data()
        if params.appKeyFlag == Data([0x01]) {
            //APP Key Flag is set, use AFK and AID from upper transport
            let aid : UInt8 = params.aid[0]
            let header = 0x40 | aid //0x40 == 0100 0000
            headerByte.append(Data([header]))
        } else {
            //No APP key used, first octet will be 0x00
            headerByte.append(Data([0x00]))
        }
        lowerData.append(Data(headerByte))
        lowerData.append(Data(params.upperTransportData))
        print("""
↗️ Lower Transport Layer unsegmented access message:
  Header byte: \(headerByte.hexString())
  AKF: \(params.appKeyFlag == Data([0x01]) ? "Set" : "Not set")
  AID: \(params.appKeyFlag == Data([0x01]) ? String(format: "0x%02X", params.aid[0]) : "N/A")
  Upper transport data: \(params.upperTransportData.hexString())
  Complete PDU: \(lowerData.hexString())
""")
        return lowerData
    }

    private func createSegmentedAccessMessage() -> [Data] {
        var chunkedData = [Data]()
        let chunkSize   = 12 //12 bytes is the max
        let chunkRanges = calculateDataRanges(params.upperTransportData, withSize: chunkSize)
        let sequenceData = params.sequenceNumber.sequenceData()
        var debugInfo = "↗️ Lower Transport Layer segmented access message:"

        for (index, aChunkRange) in chunkRanges.enumerated() {
            var headerByte  = Data()
            if params.appKeyFlag == Data([0x01]) {
                //APP Key flag is set, use AFK and AID from upper transport
                //Octet 0 is 11xx xxx == where xx xxx is AID
                let header = 0xC0 | params.aid[0]
                headerByte.append(Data([header]))
            } else {
                //No Appkey used, Octet 0 is 1000 0000 == 0x80
                headerByte.append(Data([0x80]))
            }
            var currentChunk = Data()
            let segO = UInt8(index)
            let segN = UInt8(chunkRanges.count - 1) //0 index
            var bytes: UInt8 = (params.szMIC[0] << 7 ) | ((sequenceData[1] << 2) & 0x7F) | (sequenceData[2] >> 6)
            headerByte.append(Data([bytes]))
            bytes = (sequenceData[2] << 2) | (segO >> 3)
            headerByte.append(Data([bytes]))
            bytes = (segO << 5) | (segN & 0x1F)
            headerByte.append(Data([bytes]))
            let sequenceZero = (UInt16(headerByte[1] & 0x7F) << 6) | UInt16(headerByte[2] >> 2)
            //Append header
            currentChunk.append(Data(headerByte))
            //Then append current chunk
            currentChunk.append(Data(params.upperTransportData.subdata(in: aChunkRange)))
            let chunk = Data(currentChunk)
            chunkedData.append(chunk)

            debugInfo += """

  Chunk \(index + 1):
    Data: \(chunk.hexString())
    Sequence Zero: \(Data.init(fromInt16: sequenceZero).hexString())
    SegO: \(segO)
    SegN: \(segN)
"""
        }

        print(debugInfo)
        return chunkedData
    }

    private func createUnsegmentedControlMessage() -> Data {
        var pdu = Data()
        pdu.append(Data([0x7F & params.opcode[0]]))
        pdu.append(Data(params.upperTransportData))

        print("""
        ↗️ Lower Transport Layer unsegmented control message:
          Opcode: \(Data([0x7F & params.opcode[0]]).hexString())
          Payload: \(params.upperTransportData.hexString())
          PDU: \(pdu.hexString())
        """)

        return pdu
    }

    private func createSegmentedControlMessage() -> [Data] {
        var chunkedData = [Data]()
        let chunkSize = 8 // 8 bytes is the max for control messages
        let chunkRanges = calculateDataRanges(params.upperTransportData, withSize: chunkSize)
        let sequenceData = params.sequenceNumber.sequenceData()
        let sequenceZero = UInt16((sequenceData[1] << 6) | (sequenceData[2] >> 2))

        var debugInfo = """
        ↗️ Lower Transport Layer segmented control message:
          Chunk size: \(chunkSize)
          Number of chunks: \(chunkRanges.count)
          Sequence Zero: \(Data.init(fromInt16: sequenceZero).hexString())

        Chunks:
        """

        for (index, aChunkRange) in chunkRanges.enumerated() {
            var headerByte = Data()
            headerByte.append(0x80 | (params.opcode[0] & 0x7F))

            let segO = UInt8(index)
            let segN = UInt8(chunkRanges.count - 1)

            var bytes: UInt8 = ((sequenceData[1] << 2) & 0x7F) | (sequenceData[2] >> 6)
            headerByte.append(bytes)
            bytes = (sequenceData[2] << 2) | (segO >> 3)
            headerByte.append(bytes)
            bytes = (segO << 5) | (segN & 0x1F)
            headerByte.append(bytes)

            var currentChunk = Data()
            currentChunk.append(headerByte)
            currentChunk.append(params.upperTransportData.subdata(in: aChunkRange))
            chunkedData.append(currentChunk)

            debugInfo += """

              Chunk \(index + 1):
                Data: \(currentChunk.hexString())
                SegO: \(segO)
                SegN: \(segN)
            """
        }

        print(debugInfo)
        return chunkedData
    }

    // MARK: - Helpers
    private func isSegmented() -> Bool {
        return params.segmented == Data([0x01])
    }

    private func calculateDataRanges(_ someData: Data, withSize aChunkSize: Int) -> [Range<Int>] {
        var totalLength = someData.count
        var ranges = [Range<Int>]()
        var partIdx = 0
        while (totalLength > 0) {
            var range : Range<Int>
            if totalLength > aChunkSize {
                totalLength -= aChunkSize
                range = (partIdx * aChunkSize) ..< aChunkSize + (partIdx * aChunkSize)
            } else {
                range = (partIdx * aChunkSize) ..< totalLength + (partIdx * aChunkSize)
                totalLength = 0
            }
            ranges.append(range)
            partIdx += 1
        }
        return ranges
    }
}
