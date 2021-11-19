//
//  SleepConfiguratorState.swift
//  nRFMeshProvision
//
//  Created by Mostafa Berg on 06/04/2018.
//

import CoreBluetooth
import Foundation

class SleepConfiguratorState: NSObject, ConfiguratorStateProtocol {
    
    // MARK: - Properties
    private var proxyService            : CBService!
    private var dataInCharacteristic    : CBCharacteristic!
    private var dataOutCharacteristic   : CBCharacteristic!
    private var segmentedData: Data = Data()
    private var lastMessageType = 0xC0

    // MARK: - ConfiguratorStateProtocol
    var destinationAddress  : Data
    var target              : ProvisionedMeshNodeProtocol
    var stateManager        : MeshStateManager
    
    required init(withTargetProxyNode aNode: ProvisionedMeshNodeProtocol,
                  destinationAddress aDestinationAddress: Data,
                  andStateManager aStateManager: MeshStateManager) {
        target = aNode
        stateManager = aStateManager
        destinationAddress = aDestinationAddress
        super.init()
        target.basePeripheral().delegate = self
        //If services and characteristics are already discovered, set them now
        let discovery           = target.discoveredServicesAndCharacteristics()
        proxyService            = discovery.proxyService
        dataInCharacteristic    = discovery.dataInCharacteristic
        dataOutCharacteristic   = discovery.dataOutCharacteristic
    }
    
    func humanReadableName() -> String {
        return "Sleep"
    }
    
    func execute() {
        print("Sleeping indefinitely")
    }
    
    func receivedData(incomingData : Data) {
        if incomingData[0] == 0x01 {
            print("Secure beacon: \(incomingData.hexString())")
            let strippedOpcode = Data(incomingData.dropFirst())
            target.delegate?.receivedSecureBeacon(strippedOpcode);
            
        } else {
//            let strippedOpcode = Data(incomingData.dropFirst())
//            if let result = networkLayer.incomingPDU(strippedOpcode) {
//                if result is AppKeyStatusMessage {
//                    let appKeyStatus = result as! AppKeyStatusMessage
//                    if appKeyStatus.statusCode == .success {
//                        //Store newly added AppKey to global list
//                        let state = self.stateManager.state()
//                        if let anIndex = state.nodes.index(where: { $0.nodeUnicast == destinationAddress}) {
//                            let aNodeEntry = state.nodes[anIndex]
//                            state.nodes.remove(at: anIndex)
//                            if aNodeEntry.appKeys.contains(appKeyStatus.appKeyIndex) == false {
//                                aNodeEntry.appKeys.append(appKeyStatus.appKeyIndex)
//                            }
//                            state.nodes.append(aNodeEntry)
//                            stateManager.saveState()
//                        }
//                    } else {
//                        print("App key add error : \(appKeyStatus.statusCode)")
//                        target.shouldDisconnect()
//                    }
//                    target.delegate?.receivedAppKeyStatusData(appKeyStatus)
//                } else {
//                    print("Ignoring non app key status message")
//                }
//            }
        }
    }
    
    // MARK: - CBPeripheralDelegate
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        //NOOP
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        //NOOP
    }
    
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
            segmentedData.append(characteristic.value!.dropFirst())
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
        print("Ignoring notification state changed, sleeping...")
    }
}
