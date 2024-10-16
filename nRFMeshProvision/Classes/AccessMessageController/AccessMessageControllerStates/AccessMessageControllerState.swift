//
//  AcccessMessgeController
//

import CoreBluetooth
import Foundation

class AccessMessageControllerState: NSObject, GenericModelControllerStateProtocol {
    // MARK: - Properties

    private var proxyService: CBService!
    private var dataInCharacteristic: CBCharacteristic!
    private var dataOutCharacteristic: CBCharacteristic!
    private var networkLayer: NetworkLayer!
    private var segmentedData: Data
    private var opcode: Data?
    private var payload: Data?
    private var key: Data?
    private var isConfig: Bool?

    // MARK: - ConfiguratorStateProtocol

    var destinationAddress: Data
    var target: ProvisionedMeshNodeProtocol
    var stateManager: MeshStateManager
    var payloads: [Data]?
    var accessMessage: AccessMessagePDU?
    required init(withTargetProxyNode aNode: ProvisionedMeshNodeProtocol,
                  destinationAddress aDestinationAddress: Data,
                  andStateManager aStateManager: MeshStateManager)
    {
        target = aNode
        segmentedData = Data()
        stateManager = aStateManager
        destinationAddress = aDestinationAddress
        super.init()
        target.basePeripheral().delegate = self
        // If services and characteristics are already discovered, set them now
        let discovery = target.discoveredServicesAndCharacteristics()
        proxyService = discovery.proxyService
        dataInCharacteristic = discovery.dataInCharacteristic
        dataOutCharacteristic = discovery.dataOutCharacteristic

        networkLayer = NetworkLayer(withStateManager: stateManager, andSegmentAcknowlegdement: { ackData in
            self.acknowlegeSegment(withAckData: ackData)
        })
    }

    public func setPayload(payload payloadData: Data) {
        payload = payloadData
    }

    public func setOpcode(opcode opcodeData: Data) {
        opcode = opcodeData
    }

    public func setKey(key keyData: Data) {
        key = keyData
    }

    public func setIsConfig(withConfig isConfig: Bool) {
        self.isConfig = isConfig
    }

    func humanReadableName() -> String {
        return "Access message"
    }

    func execute() {
        if let appKey = stateManager.state().appKeys.first?.key {
            let aState = stateManager.state()
            guard payload != nil && opcode != nil && key != nil && isConfig != nil else {
                return
            }
            accessMessage = isConfig! ? AccessMessagePDU(
                withPayload: payload!,
                opcode: opcode!,
                deviceKey: key!,
                netKey: aState.netKeys[0].key,
                seq: SequenceNumber(),
                ivIndex: aState.netKeys[0].phase,
                source: aState.unicastAddress,
                andDst: destinationAddress
            ) :
                AccessMessagePDU(
                    withPayload: payload!,
                    opcode: opcode!,
                    appKey: key!,
                    netKey: aState.netKeys[0].key,
                    seq: SequenceNumber(),
                    ivIndex: aState.netKeys[0].phase,
                    source: aState.unicastAddress,
                    andDst: destinationAddress,
                    ttl: Data([0x08])
                )
            payloads = accessMessage?.assembleNetworkPDU()
            // Send to destination
            for aPayload in payloads! {
                sendPayload(aPayload)
            }
        } else {
            // TODO: handle error
            print("Error: AppKey Not present, returning nil")
            return
        }

        // we stay in this state, as we might have to handle acks in this state,
        // only after receiving a message, we switch to the sleep config state
        target.delegate?.sentAccessMessageUnacknowledged(destinationAddress)
    }

    func receivedData(incomingData: Data) {
        // Receiving is
        if incomingData[0] == 0x01 {
            print("Secure beacon: \(incomingData.hexString())")
        } else {
            let strippedOpcode = Data(incomingData.dropFirst())
            if let result = networkLayer.incomingPDU(strippedOpcode, withRawAccess: true) {
                if result is GenericAccessMessage {
                    let status = result as! GenericAccessMessage
                    target.delegate?.receivedAccessMessage(status)
                    let nextState = SleepConfiguratorState(withTargetProxyNode: target, destinationAddress: destinationAddress, andStateManager: stateManager)
                    target.switchToState(nextState)
                } else if result is SegmentAcknowledgmentMessage {
                    let segmentAckMsg = result as! SegmentAcknowledgmentMessage
                    if let allPayloads = payloads, allPayloads.count > 0 && !segmentAckMsg.areAllSegmentsReceived(lastSegmentNumber: UInt8(allPayloads.count - 1)) {
                        print("needs to handle segment ack")
                        if let msg = accessMessage {
                            if let payloads = msg.networkLayer?.handleSegmentAcknowledgmentMessage(segmentAckMsg) {
                                print("re-sending payloads: \(payloads.count)")
                                for aPayload in payloads {
                                    sendPayload(aPayload)
                                }
                            }
                        }
                    }
                } else {
                    print("got unhandled message")
                }
            } else {
                print("ignoring unknown status message")
            }
        }
    }

    func sendPayload(_ aPayload: Data) {
        var data = Data([0x00]) // Type => Network
        data.append(aPayload)
        print("Full PDU: \(data.hexString())")
        if data.count <= target.basePeripheral().maximumWriteValueLength(for: .withoutResponse) {
            print("Sending  data: \(data.hexString())")
            target.basePeripheral().writeValue(data, for: dataInCharacteristic, type: .withoutResponse)
        } else {
            print("maximum write length is shorter than PDU, will Segment")
            var segmentedProvisioningData = [Data]()
            data = Data(data.dropFirst()) // Drop old network header, SAR will now set that instead.
            let chunkRanges = calculateDataRanges(data, withSize: 19)
            for aRange in chunkRanges {
                var header = Data()
                let chunkIndex = chunkRanges.index(of: aRange)!
                if chunkIndex == 0 {
                    header.append(Data([0x40])) // SAR start
                } else if chunkIndex == chunkRanges.count - 1 {
                    header.append(Data([0xC0])) // SAR end
                } else {
                    header.append(Data([0x80])) // SAR cont.
                }
                var chunkData = Data(header)
                chunkData.append(Data(data[aRange]))
                segmentedProvisioningData.append(Data(chunkData))
            }
            for aSegment in segmentedProvisioningData {
                print("Sending segment: \(aSegment.hexString())")
                target.basePeripheral().writeValue(aSegment, for: dataInCharacteristic, type: .withoutResponse)
            }
        }
    }

    private func calculateDataRanges(_ someData: Data, withSize aChunkSize: Int) -> [Range<Int>] {
        var totalLength = someData.count
        var ranges = [Range<Int>]()
        var partIdx = 0
        while totalLength > 0 {
            var range: Range<Int>
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

    private func acknowlegeSegment(withAckData someData: Data) {
        print("Sending acknowledgement: \(someData.hexString())")
        if someData.count <= target.basePeripheral().maximumWriteValueLength(for: .withoutResponse) {
            target.basePeripheral().writeValue(someData, for: dataInCharacteristic, type: .withoutResponse)
        } else {
            print("Maximum write length is shorter than ACK PDU, will Segment")
            var segmentedData = [Data]()
            let dataToSegment = Data(someData.dropFirst()) // Remove old header as it's going to be added in SAR
            let chunkRanges = calculateDataRanges(dataToSegment, withSize: 19)
            for aRange in chunkRanges {
                var header = Data()
                let chunkIndex = chunkRanges.index(of: aRange)!
                if chunkIndex == 0 {
                    header.append(Data([0x40])) // SAR start
                } else if chunkIndex == chunkRanges.count - 1 {
                    header.append(Data([0xC0])) // SAR end
                } else {
                    header.append(Data([0x80])) // SAR cont.
                }
                var chunkData = Data(header)
                chunkData.append(Data(dataToSegment[aRange]))
                segmentedData.append(Data(chunkData))
            }
            for aSegment in segmentedData {
                print("Sending Ack segment: \(aSegment.hexString())")
                target.basePeripheral().writeValue(aSegment, for: dataInCharacteristic, type: .withoutResponse)
            }
        }
    }

    // MARK: - CBPeripheralDelegate

    func peripheral(_: CBPeripheral, didDiscoverServices _: Error?) {
        // NOOP
    }

    func peripheral(_: CBPeripheral, didDiscoverCharacteristicsFor _: CBService, error _: Error?) {
        // NOOP
    }

    var lastMessageType = 0xC0

    func peripheral(_: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error _: Error?) {
        print("Characteristic value updated: \(characteristic.value!.hexString())")
        // SAR handling
        if characteristic.value![0] & 0xC0 == 0x40 {
            if lastMessageType == 0x40 {
                // Drop repeated 0x40's
                print("CMP:Reduntand SAR start, dropping")
                segmentedData = Data()
            }
            lastMessageType = 0x40
            // Add message type header
            segmentedData.append(Data([characteristic.value![0] & 0x3F]))
            segmentedData.append(Data(characteristic.value!.dropFirst()))
        } else if characteristic.value![0] & 0xC0 == 0x80 {
            lastMessageType = 0x80
            print("Segmented data cont")
            segmentedData.append(characteristic.value!.dropFirst())
        } else if characteristic.value![0] & 0xC0 == 0xC0 {
            lastMessageType = 0xC0
            print("Segmented data end")
            segmentedData.append(Data(characteristic.value!.dropFirst()))
            print("Reassembled data!: \(segmentedData.hexString())")
            // Copy data and send it to NetworkLayer
            receivedData(incomingData: Data(segmentedData))
            segmentedData = Data()
        } else {
            receivedData(incomingData: Data(characteristic.value!))
        }
    }

    func peripheral(_: CBPeripheral, didUpdateNotificationStateFor _: CBCharacteristic, error _: Error?) {
        print("Characteristic notification state changed")
    }
}
