//
//  ConfirmationProvisioningState.swift
//  nRFMeshProvision
//
//  Created by Mostafa Berg on 21/12/2017.
//

import Foundation
import CoreBluetooth
import Security

class ConfirmationProvisioningState: NSObject, ProvisioningStateProtocol {

    // MARK: - Properties
    private var provisioningService: CBService!
    private var dataInCharacteristic: CBCharacteristic!
    private var dataOutCharacteristic: CBCharacteristic!
    
    // MARK: - State properties
    private var authValue: Data?

    // MARK: - ProvisioningStateProtocol
    var target: UnprovisionedMeshNodeProtocol

    func humanReadableName() -> String {
        return "Provisioning confirmation"
    }

    required init(withTargetNode aNode: UnprovisionedMeshNodeProtocol) {
        target                              = aNode
        super.init()
        target.basePeripheral().delegate    = self
        //If services and characteristics are already discovered, set them now
        let discovery                       = target.discoveredServicesAndCharacteristics()
        provisioningService                 = discovery.provisionService
        dataInCharacteristic                = discovery.dataInCharacteristic
        dataOutCharacteristic               = discovery.dataOutCharacteristic
    }
    
//    public static byte[] getInputOOOBAuthenticationValue(final short inputOOBAction, final byte size) {
//    switch (fromValue(inputOOBAction)) {
//    case PUSH:
//    case TWIST:
//    //We override the value here to 1 so we generate a 1 digit value for presses.
//    return MeshParserUtils.generateOOBCount(1);
//    case INPUT_NUMERIC:
//    return MeshParserUtils.generateOOBNumeric(size);
//    case INPUT_ALPHA_NUMERIC:
//    return MeshParserUtils.generateOOBAlphaNumeric(size);
//    default:
//    return null;
//    }
//    }

    func getInputOOOBAuthenticationValue(oobAction: InputOutOfBoundActions, size: Int) -> Data {
        switch oobAction {
        case .push, .twist:
            return Data([UInt8.random(in: 0 ..< 10)])
        case .inputNumber:
            let range = ClosedRange(uncheckedBounds: (lower: 0, upper: NSDecimalNumber(decimal: pow(10, size)).uint32Value))
            return Data(fromInt32: UInt32.random(in: range))
        case .inputAlphaNumeric:
            let letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
            return Data(String((0 ..< size).map{ _ in letters.randomElement()!}).utf8.map{UInt8($0)})
        default:
            return Data()
        }
    }
    
    func execute() {
        let capabilities = target.provisioningExchangeData().capabilitiesData
        let provisioningData = target.provisioningUserData();
        
        switch provisioningData.oobType {
        case .outputOOB:
            print("Output OOB used")
            print("Requires user input...")
            let targetAction = provisioningData.oobAction as! OutputOutOfBoundActions
            let actionLength = capabilities[7]
            target.requireUserInput(outputActionType: targetAction, outputLength: actionLength) { (anInput) -> (Void) in
                DispatchQueue.main.async {
                    let intValue                    = CFSwapInt32BigToHost(UInt32(anInput)!)
                    self.didReceiveAuthValue(Data(bytes: self.toByteArray(intValue)))
                }
            }
        case .inputOOB:
            print("Input OOB used")
            let targetAction = provisioningData.oobAction as! InputOutOfBoundActions
            let inputSize = Int(capabilities[10]);
            let authValue = getInputOOOBAuthenticationValue(oobAction: targetAction, size: inputSize);
            target.receivedProvisionerAuthValue(authValue)
            let authValueString = String(data: authValue, encoding: String.Encoding.utf8) ?? ""
            target.requireDeviceInput(inputActionType: targetAction, anInput: authValueString)
            print("choosen authvalue \(authValue.hexString())")
        case .staticOOB:
            print("Static OOB used")
            target.requireStaticInput  { (anInput) -> (Void) in
                DispatchQueue.main.async {
                    self.didReceiveAuthValue(Data(hexString: anInput) ?? Data())
                }
            }
            break;
        default:
            print("No OOB used")
            self.didReceiveAuthValue(Data())
            break;
        }
//        let supportedOutputActions = OutputOutOfBoundActions.calculateOutputActionsFromBitMask(aBitMask: UInt16(capabilities[8] << 0xFF) + UInt16(capabilities[9] & 0x00FF))
//        if supportedOutputActions.count == 0 || supportedOutputActions.contains(.noOutput) {
//            print("No OutputOOB capabilities")
//            let simulatedEmptyInputStringForNoAction = "0000000000000000"
//            self.didreceiveUserInput(simulatedEmptyInputStringForNoAction)
//        } else {
//            print("Requires user input...")
//            if supportedOutputActions.count > 0 {
//                if supportedOutputActions.first != nil {
//                    let targetAction = supportedOutputActions.first!
//                    let actionLength = capabilities[7]
//                    target.requireUserInput(outputActionType: targetAction, outputLength: actionLength) { (anInput) -> (Void) in
//                        DispatchQueue.main.async {
//                            self.didreceiveUserInput(anInput)
//                        }
//                    }
//                }
//            }
//        }
        // TODO: other output possibilities
    }

    func didReceiveAuthValue(_ anAuthValue: Data) {
        //Generate ConfirmationInputs
        let confirmationInputs          = generateConfirmationInputsFromTarget(target)
        print("confirmationInputs: \(confirmationInputs.hexString())")
        //Next step, AES-CMAC confirmationKey with ECDHSectret
        let helper                      = OpenSSLHelper()
        //Get salt (s1) from confirmationInputs.
        let salt                        = helper.calculateSalt(confirmationInputs)
        print("Salt: \(salt!.hexString())")
        //AES-CMAC Confirmation key with ECDH Secret
        let ecdh                        = target.provisioningExchangeData().ecdhData
        print("ecdh: \(ecdh.hexString())")
        //Then calculace K1 (outputs the confirmationKey)
        //K1 function takes N, SALT & P as parameters
        //In our case, N is the ECDH Secret, SALT is S1 using confirmationInputs, and P is prck ASCII
        //T is calculated first using AES-CMAC ecdh with salt S1
        //Then calculating AES-CMAC P with salt T
        let t                           = helper.calculateCMAC(ecdh, andKey: salt)
        //PRCK => 7072636b (ASCII)
        let confirmationKey             = helper.calculateCMAC(Data([0x70, 0x72, 0x63, 0x6b]), andKey: t)
        print("confirmationKey: \(confirmationKey!.hexString())")
        //Next step is to calculate the confirmation provisioner value
        //This is done by calculating AES-CMAC of (Random value || AuthVAlue) with salt (confirmationKey)
        let authBytes                   = anAuthValue.leftPad(length: 16)
        print("authBytes: \(authBytes.hexString())")
        target.receivedProvisionerAuthValue(authBytes)
        if let randomProvisioner        = helper.generateRandom() {
            var confirmationData        = randomProvisioner
            confirmationData.append(contentsOf: authBytes)
            let confirmationValue       = helper.calculateCMAC(confirmationData, andKey: confirmationKey!)
            target.generatedProvisionerConfirmationValue(confirmationValue!)
            print("ConfirmationVal: \(confirmationValue!.hexString())")
            target.generatedProvisionerRandom(randomProvisioner)
            print("randomProv: \(randomProvisioner.hexString())")
            var confirmationPDUArray    = Data(bytes: [0x03, 0x05])
            confirmationPDUArray.append(confirmationValue!)
            target.basePeripheral().writeValue(confirmationPDUArray, for: dataInCharacteristic, type: .withoutResponse)
            print("Confirmation PDU sent: \(confirmationPDUArray.hexString())")
        } else {
            print("Generation failed ...")
            return
        }
   }

    func toByteArray<T>(_ value: T) -> [UInt8] {
        var value = value
        return withUnsafeBytes(of: &value) { Array($0) }
    }

    private func generateConfirmationInputsFromTarget(_ aTarget: UnprovisionedMeshNodeProtocol) -> Data {
        let data      = aTarget.provisioningExchangeData()
        //invite: 1 bytes, capabilities: 11 bytes, start: 5 bytes, provisionerKey: 64 bytes, deviceKey: 64 bytes
        return data.inviteData + data.capabilitiesData + data.startData + data.provisionerKeyData + data.deviceKeyData
    }

    // MARK: - CBPeripheralDelegate
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        //NOOP
    }
   
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        //NOOP
    }
   
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if (target.provisioningUserData().oobType == .inputOOB) {
            if characteristic.value![0] == 0x03 && characteristic.value![1] == 0x04 {
                let authValue = target.provisionerAuthData()
                self.didReceiveAuthValue(authValue)
                return;
            }
        }
        
        guard characteristic.value![0] == 0x03 && characteristic.value![1] == 0x05 else {
            print("Received wrong PDU, expected 0x03 0x05")
            print("Received \(characteristic.value![0]) \(characteristic.value![1]) instead.")
            return
        }

        //First two bytes are PDU and are not used in verification
        let deviceConfirmation = characteristic.value!.dropFirst().dropFirst()
        target.receivedDeviceConfirmationValue(deviceConfirmation)
        let nextState = RandomConfirmationProvisioningState(withTargetNode: target)
        target.switchToState(nextState)
    }
   
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        //NOOP
    }
}
