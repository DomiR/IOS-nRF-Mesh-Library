//
//  ModelAppBindConfiguratorState.swift
//  nRFMeshProvision
//
//  Created by Mostafa Berg on 13/04/2018.
//

import CoreBluetooth
import Foundation

class ConfigProxySetConfiguratorState: NSObject, ConfiguratorStateProtocol {

    // MARK: - Properties
    private var proxyService            : CBService!
    private var dataInCharacteristic    : CBCharacteristic!
    private var dataOutCharacteristic   : CBCharacteristic!
    private var networkLayer            : NetworkLayer!
    private var proxy: Int!
    private var segmentedData: Data

    // MARK: - ConfiguratorStateProtocol
    var destinationAddress  : Data
    var target              : ProvisionedMeshNodeProtocol
    var stateManager        : MeshStateManager

    required init(withTargetProxyNode aNode: ProvisionedMeshNodeProtocol,
                  destinationAddress aDestinationAddress: Data,
                  andStateManager aStateManager: MeshStateManager) {
        target = aNode
        segmentedData = Data()
        stateManager = aStateManager
        destinationAddress = aDestinationAddress
        super.init()
        target.basePeripheral().delegate = self
        //If services and characteristics are already discovered, set them now
        let discovery           = target.discoveredServicesAndCharacteristics()
        proxyService            = discovery.proxyService
        dataInCharacteristic    = discovery.dataInCharacteristic
        dataOutCharacteristic   = discovery.dataOutCharacteristic

        networkLayer = NetworkLayer(withStateManager: stateManager, andSegmentAcknowlegdement: { (ackData) -> (Void) in
            self.acknowlegeSegment(withAckData: ackData)
        })
    }

    public func setProxy(withProxy proxy: Int) {
        self.proxy = proxy;
    }

    func humanReadableName() -> String {
        return "Config Proxy Set"
    }

    func execute() {
        let message = ConfigProxySetMessage(withProxy: proxy);
        //Send to destination (unicast)
        let payloads = message.assemblePayload(withMeshState: stateManager.state(), toAddress: destinationAddress)
        for aPayload in payloads! {
            var data = Data([0x00]) //Type => Network
            data.append(aPayload)
            if data.count <= target.basePeripheral().maximumWriteValueLength(for: .withoutResponse) {
                print("Sending config proxy set data: \(data.hexString())")
                target.basePeripheral().writeValue(data, for: dataInCharacteristic, type: .withoutResponse)
            } else {
                print("maximum write length is shorter than PDU, will Segment")
                var segmentedProvisioningData = [Data]()
                data = Data(data.dropFirst()) //Drop old network header, SAR will now set that instead.
                let chunkRanges = self.calculateDataRanges(data, withSize: 19)
                for aRange in chunkRanges {
                    var header = Data()
                    let chunkIndex = chunkRanges.index(of: aRange)!
                    if chunkIndex == 0 {
                        header.append(Data([0x40])) //SAR start
                    } else if chunkIndex == chunkRanges.count - 1 {
                        header.append(Data([0xC0])) //SAR end
                    } else {
                        header.append(Data([0x80])) //SAR cont.
                    }
                    var chunkData = Data(header)
                    chunkData.append(Data(data[aRange]))
                    segmentedProvisioningData.append(Data(chunkData))
                }
                for aSegment in segmentedProvisioningData {
                    print("Sending model app bind segment: \(aSegment.hexString())")
                    target.basePeripheral().writeValue(aSegment, for: dataInCharacteristic, type: .withoutResponse)
                }
            }
        }
    }

    func receivedData(incomingData : Data) {
        if incomingData[0] == 0x01 {
            print("Secure beacon: \(incomingData.hexString())")
        } else {
            print("Incoming DPU: \(incomingData.hexString())")
            let strippedOpcode = Data(incomingData.dropFirst())
            if let result = networkLayer.incomingPDU(strippedOpcode) {
                if result is ConfigProxyStatusMessage {
                    let configProxyStatus = result as! ConfigProxyStatusMessage
                    print("configProxyStatus: \(configProxyStatus.debugDescription)")
                    //Store newly added bound AppKey to global list
                    /*
                    let state = self.stateManager.state()
                    if let anIndex = state.nodes.index(where: { $0.nodeUnicast == destinationAddress}) {
                        let aNodeEntry = state.nodes[anIndex]
                        state.nodes.remove(at: anIndex)
                        if var nodeElements = aNodeEntry.elements {
                            if let elementIdx = aNodeEntry.getElementIndex(withUnicast: elementAddress) {
                                var element = nodeElements[elementIdx];
                                aNodeEntry.elements!.remove(at: elementIdx);
                                element.setKeyBinding(appKeyIndex, forModelId: modelIdentifier);
                                aNodeEntry.elements!.append(element)
                            }
                        }
                        state.nodes.append(aNodeEntry)
                        stateManager.saveState()
                    }
                    */
                    target.delegate?.receivedProxyConfig(configProxyStatus)
                } else {
                    print("Ignoring non model app status message")
                }
            }
        }
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

    private func acknowlegeSegment(withAckData someData: Data) {
        print("Sending acknowledgement: \(someData.hexString())")
        if someData.count <= self.target.basePeripheral().maximumWriteValueLength(for: .withoutResponse) {
            self.target.basePeripheral().writeValue(someData, for: self.dataInCharacteristic, type: .withoutResponse)
        } else {
            print("Maximum write length is shorter than ACK PDU, will Segment")
            var segmentedData = [Data]()
            let dataToSegment = Data(someData.dropFirst()) //Remove old header as it's going to be added in SAR
            let chunkRanges = self.calculateDataRanges(dataToSegment, withSize: 19)
            for aRange in chunkRanges {
                var header = Data()
                let chunkIndex = chunkRanges.index(of: aRange)!
                if chunkIndex == 0 {
                    header.append(Data([0x40])) //SAR start
                } else if chunkIndex == chunkRanges.count - 1 {
                    header.append(Data([0xC0])) //SAR end
                } else {
                    header.append(Data([0x80])) //SAR cont.
                }
                var chunkData = Data(header)
                chunkData.append(Data(dataToSegment[aRange]))
                segmentedData.append(Data(chunkData))
            }
            for aSegment in segmentedData {
                print("Sending Ack segment: \(aSegment.hexString())")
                self.target.basePeripheral().writeValue(aSegment, for: self.dataInCharacteristic, type: .withoutResponse)
            }
        }
    }

    // MARK: - CBPeripheralDelegate
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        //NOOP
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        //NOOP
    }

    var lastMessageType = 0xC0

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        print("Characteristic value updated: \(characteristic.value!.hexString())")
        //SAR handling
        if characteristic.value![0] & 0xC0 == 0x40 {
            if lastMessageType == 0x40 {
                //Drop repeated 0x40's
                print("CMP:Reduntand SAR start, dropping")
                segmentedData = Data()
            }
            lastMessageType = 0x40
            //Add message type header
            segmentedData.append(Data([characteristic.value![0] & 0x3F]))
            segmentedData.append(Data(characteristic.value!.dropFirst()))
        } else if characteristic.value![0] & 0xC0 == 0x80 {
            lastMessageType = 0x80
            print("Segmented data cont")
            segmentedData.append(Data(characteristic.value!.dropFirst()))
        } else if characteristic.value![0] & 0xC0 == 0xC0 {
            lastMessageType = 0xC0
            print("Segmented data end")
            segmentedData.append(Data(characteristic.value!.dropFirst()))
            print("Reassembled data!: \(segmentedData.hexString())")
            //Copy data and send it to NetworkLayer
            receivedData(incomingData: Data(segmentedData))
            segmentedData = Data()
        } else {
            receivedData(incomingData: Data(characteristic.value!))
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        print("Characteristic notification state changed")
    }
}
