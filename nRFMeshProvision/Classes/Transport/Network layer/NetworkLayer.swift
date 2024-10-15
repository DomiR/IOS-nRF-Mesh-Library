//
//  NetworkLayer.swift
//  nRFMeshProvision
//
//  Created by Mostafa Berg on 20/02/2018.
//

import Foundation

public struct NetworkLayer {
    var stateManager        : MeshStateManager?
    var lowerTransport      : LowerTransportLayer!
    var netKey              : Data
    var sslHelper           : OpenSSLHelper
    var ivIndex             : Data!

    public init(withStateManager aStateManager: MeshStateManager,
                andSegmentAcknowlegdement aSegmentAckBlock: SegmentedMessageAcknowledgeBlock? = nil) {
        stateManager = aStateManager
        netKey = aStateManager.meshState.netKeys[0].key
        ivIndex = aStateManager.meshState.netKeys[0].phase
        sslHelper = OpenSSLHelper()
        lowerTransport = LowerTransportLayer(withStateManager: aStateManager,
                                             andSegmentedAcknowlegdeMent: aSegmentAckBlock)
    }

    public mutating func incomingPDU(_ aPDU : Data, withRawAccess rawAccess: Bool = false) -> Any? {
        let k2Output = sslHelper.calculateK2(withN: netKey, andP: Data([0x00]))!
        let networkNid = k2Output[0] & 0x7F
        let ivi = ivIndex[3] & 0x01; // least significant bit of IV Index
        let calculactedIVINid = (ivi << 7) | networkNid
        guard calculactedIVINid == aPDU.first else {
            print("network Expected IV Index||NID did not match packet data, message is malfromed. NOOP")
            return nil
        }
        let encryptionKey = k2Output[1..<17]
        let privacyKey = k2Output[17..<33]
        let deobfuscatedPDU = sslHelper.deobfuscateENCPDU(aPDU, ivIndex: ivIndex, privacyKey: privacyKey)!
        let ctlttl = deobfuscatedPDU[0]
        let ctl = UInt8(ctlttl >> 7) == 0x01 ? true : false
        let ctlData = ctl ? Data([0x01]) : Data([0x00])
        let ttl = Data([ctlttl & 0x7F])
        let seq = deobfuscatedPDU[1..<4]
        let src = deobfuscatedPDU[4..<6]
        let micSize: Int = ctl ? 8 : 4

        //Decrypt network PDU
        let encryptedNetworkPDU = Data(aPDU[7...(aPDU.count - micSize - 1)]) //7 first bytes are not a part of the ENCPDU
        let netMic = Data(aPDU[(7 + encryptedNetworkPDU.count)..<(7 + encryptedNetworkPDU.count + micSize)])
        let nonceData = TransportNonce(networkNonceWithIVIndex: ivIndex, ctl: ctlData, ttl: ttl, seq: seq, src: src).data
        let decryptedNetworkPDU = sslHelper.calculateDecryptedCCM(encryptedNetworkPDU,
                                                                  withKey: encryptionKey,
                                                                  nonce: nonceData,
                                                                  dataSize: UInt8(encryptedNetworkPDU.count), andMIC: netMic)
        let dst = decryptedNetworkPDU![0...1]
        print("""
Network Layer message received:
  PDU:           \(aPDU.hexString())
  Encrypted PDU: \(encryptedNetworkPDU.hexString())
  Net MIC:       \(netMic.hexString()) (Size: \(micSize))
  Sequence:      \(seq.hexString())
  SRC:           \(src.hexString())
  TTL:           \(ttl.hexString())
  Decrypted PDU: \(decryptedNetworkPDU!.hexString())
""")
        return self.lowerTransport.append(withNetworkLayer: self, withIncomingPDU: Data(decryptedNetworkPDU!), ctl: ctlData, ttl: ttl, src: src, dst: dst, IVIndex: ivIndex, andSEQ: seq, withRawAccess: rawAccess)
    }

    public init(withLowerTransportLayer aLowerTransport: LowerTransportLayer, andNetworkKey aNetKey: Data) {
        lowerTransport  = aLowerTransport
        netKey          = aNetKey
        sslHelper       = OpenSSLHelper()
    }

    //  P=Plaintext, OBF=Obfuscated, ENC=Encrypted with NetKey.
    //  P   P   OBF OBF OBF  OBF  ENC  ENC         ENC
    //  IVI NID CTL TTL SEQ  SRC  DST  TRANS_PDU   NETMIC
    //  [1] [7] [1] [7] [24] [16] [16] [1-16]      [32-64] (CTL:0 32, CTL:1 64)

    //Maxlen = 148 when for control messages.
    //MaxLen = 120 when for access messages.
    public func createPDU(withLowerPdus lowerPDU: [Data]) -> [Data] {
        let ivi = lowerTransport.params.ivIndex.last! & 0x01 //LSB of IVIndex
        let k2 = sslHelper.calculateK2(withN: netKey, andP: Data(bytes: [0x00]))
        let nid = k2![0]
        let iviNid = Data([(ivi << 7) | (nid & 0x7F)])

        let encryptionKey = k2![1..<17]
        let privacyKey = k2![17..<33]
        var micSize: UInt8
        let ctlTtl = Data([(lowerTransport.params.ctl[0] << 7) | (lowerTransport.params.ttl[0] & 0x7F)])

        var debugInfo = """
Network Layer message sending:
  NetKey: \(netKey.hexString())
  K2: \((k2 ?? Data()).hexString())
  Encryption Key: \(encryptionKey.hexString())
  Privacy Key: \(privacyKey.hexString())

  Encrypted PDUs:
"""

        var networkPDUs = [Data]()

        //Encrypt all PDUs
        for aPDU in lowerPDU {

            let nonce = TransportNonce(networkNonceWithIVIndex: lowerTransport.params.ivIndex, ctl: lowerTransport.params.ctl, ttl: lowerTransport.params.ttl, seq: lowerTransport.params.sequenceNumber.sequenceData(), src: lowerTransport.params.sourceAddress)
            var dataToEncrypt = Data(lowerTransport.params.destinationAddress)
            dataToEncrypt.append(aPDU)

            if lowerTransport.params.ctl == Data([0x01]) {
                micSize = 8
            } else {
                micSize = 4
            }
            let sequenceNumber = lowerTransport.params.sequenceNumber.sequenceData();
            if let encryptedData = sslHelper.calculateCCM(dataToEncrypt, withKey: encryptionKey, nonce: nonce.data, dataSize: UInt8(dataToEncrypt.count), andMICSize: micSize) {
              if let obfuscatedPDU = sslHelper.obfuscateENCPDU(encryptedData, cTLTTLValue: ctlTtl, sequenceNumber: sequenceNumber, ivIndex: lowerTransport.params.ivIndex, privacyKey: privacyKey, andsrcAddr: lowerTransport.params.sourceAddress) {
                    var aNetworkPDU = Data()
                    aNetworkPDU.append(iviNid)
                    aNetworkPDU.append(obfuscatedPDU)
                    aNetworkPDU.append(encryptedData)
                    networkPDUs.append(aNetworkPDU)
                    debugInfo += """
    PDU \(networkPDUs.count):
      Sequence number: \(sequenceNumber.hexString())
      Data to encrypt: \(dataToEncrypt.hexString())
      Nonce: \(nonce.data.hexString())
      MIC size: \(micSize)
      Encrypted PDU: \(aNetworkPDU.hexString())\n
"""
                    //Increment sequence number
                    lowerTransport.params.sequenceNumber.incrementSequneceNumber()
                }
            }

        }

        print(debugInfo)
        return networkPDUs
    }

    public func handleSegmentAcknowledgmentMessage(_ ackMsg: SegmentAcknowledgmentMessage) -> [Data]? {
        let resendSegements = lowerTransport.handleSegmentAcknowledgmentMessage(ackMsg);
        var debugInfo = """
Network Layer handling segment acknowledgment:
  Segments to resend: \(resendSegements.count)
"""
        if (resendSegements.count > 0) {
            debugInfo += """

  Resending PDUs:
    Count: \(resendSegements.count)
    PDUs: \(resendSegements.map { $0.hexString() }.joined(separator: ", "))
"""
            print(debugInfo)
            return createPDU(withLowerPdus: resendSegements)
        } else {
            print(debugInfo)
            return nil
        }
    }
}
