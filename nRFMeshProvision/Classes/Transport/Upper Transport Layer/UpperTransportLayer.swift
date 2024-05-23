//
//  UpperTransportLayer.swift
//  nRFMeshProvision
//
//  Created by Mostafa Berg on 27/02/2018.
//

import Foundation

public struct UpperTransportLayer {
    var stateManager                : MeshStateManager?
    let params                      : UpperTransportPDUParams?
    let sslHelper                   : OpenSSLHelper
    private var encryptedPayload    : Data?
    private var decryptedPayload    : Data?

    public init(withNetworkPdu aNetPDU: Data, withIncomingPDU aPDU: Data, ctl isControl: Bool, akf isApplicationKey: Bool,
                aid applicationId: Data, seq aSEQ: Data, src aSRC: Data, dst aDST: Data,
                szMIC: Int, ivIndex anIVIndex: Data, andMeshState aStateManager: MeshStateManager?) {
        stateManager = aStateManager
        sslHelper = OpenSSLHelper()
        var key: Data!
        var nonce: TransportNonce!
        
        if isApplicationKey {
            key = stateManager!.state().appKeys.first?.key
            nonce = TransportNonce(appNonceWithIVIndex: anIVIndex, isSegmented: true, seq: aSEQ, src: aSRC, dst: aDST)
        } else {
            // TODO: 11 sent us package, which it should not have?
            key = stateManager!.state().deviceKeyForUnicast(aSRC)
            nonce = TransportNonce(deviceNonceWithIVIndex: anIVIndex, isSegmented: true, szMIC: UInt8(szMIC), seq: aSEQ, src: aSRC, dst: aDST)
        }
        
        guard key != nil else {
            params = nil;
            return;
        }
        
        if isControl {
            // Control messages aren't encrypted here, forward as is
            print("upper control message, TBD")
            //let strippedDSTPDU = Data(aPDU[2..<aPDU.count])
            let opcode = Data([aNetPDU[2] & 0x7F])
            params = UpperTransportPDUParams(withPayload: Data(aNetPDU[2..<aNetPDU.count]), opcode: opcode, IVIndex: anIVIndex, key: key, ttl: Data([0x04]), seq: SequenceNumber(), src: aSRC, dst: aDST, nonce: nonce, ctl: isControl, afk: isApplicationKey, aid: applicationId)
        } else {
            let micLen = szMIC == 1 ? 8 : 4
            let dataSize = aPDU.count - micLen
            let pduData = aPDU[0..<dataSize]
            let mic = aPDU[aPDU.count - micLen..<aPDU.count]
            print("upper msg: micLen: \(micLen) dataSize: \(dataSize) pduData: \(pduData.hexString()) mic: \(mic.hexString()) key: \(key.hexString()) nonce: \(nonce.data.hexString())")
            if let decryptedData = sslHelper.calculateDecryptedCCM(pduData, withKey: key, nonce: nonce.data, dataSize: 0, andMIC: mic) {
                decryptedPayload = Data(decryptedData)
            } else {
                print("upper Decryption failed")
            }
            var opcode = Data()
            if let payload = decryptedPayload {
                if payload.count > 0 {
                    let opcodeLength = Int((payload[0] & 0xF0) >> 6);
                    opcode.append(payload[0...max(0, opcodeLength - 1)])
                    params = UpperTransportPDUParams(withPayload: payload, opcode: opcode, IVIndex: anIVIndex, key: key, ttl: Data([0x04]), seq: SequenceNumber(), src: aSRC, dst: aDST, nonce: nonce, ctl: isControl, afk: isApplicationKey, aid: applicationId)
                } else {
                    //No payload, failed to decrypt
                    print("upper decryption failure, or no payload")
                    let fixKey: Data! = (key == nil) ? Data() : key;
                    params = UpperTransportPDUParams(withPayload: Data(), opcode: Data(), IVIndex: anIVIndex, key: fixKey, ttl: Data([0x04]), seq: SequenceNumber(), src: aSRC, dst: aDST, nonce: nonce, ctl: isControl, afk: isApplicationKey, aid: applicationId)
                }
            } else {
                //no payload, failed to decrypt
                print("upper decryption failure, or no payload")
                params = UpperTransportPDUParams(withPayload: Data(), opcode: Data(), IVIndex: anIVIndex, key: key, ttl: Data([0x04]), seq: SequenceNumber(), src: aSRC, dst: aDST, nonce: nonce, ctl: isControl, afk: isApplicationKey, aid: applicationId)
            }
        }
    }

    public init(withParams someParams: UpperTransportPDUParams) {
        params = someParams
        sslHelper = OpenSSLHelper()
    }

    public func assembleMessage(withRawAccess rawAccess: Bool = false) -> Any? {
        guard params != nil else {
            return nil;
        }
        
        if params!.ctl {
            //Assemble control message
            print("upper assemble control 0x\(params!.opcode.hexString()), 0x\(params!.payload.hexString())")
            if (params!.opcode == Data([0x00])){
                print("Segment ack message")
                return SegmentAcknowledgmentMessage(withPayload: params!.payload, andSourceAddress: params!.sourceAddress)
            }
            return nil
        } else {
            //Assemble access message
            print("Received Access PDU \(params!.payload.hexString())")
            //let messageParser = AccessMessageParser()
            let payload = Data(decryptedPayload!.dropFirst(params!.opcode.count))
            if (rawAccess) {
                return GenericAccessMessage(withOpcode: params!.opcode, andPayload: payload, andSourceAddress: params!.sourceAddress)
            } else {
                return AccessMessageParser.parseData(payload, withOpcode: params!.opcode, sourceAddress: params!.sourceAddress)
            }
        }
    }

    public func decrypted() -> Data? {
        return decryptedPayload
    }
    public func rawData() -> Data? {
        return params!.payload
    }

    public func encrypt() -> Data? {
        if let addressType = MeshAddressTypes(rawValue: params!.destinationAddress) {
            switch addressType {
                case .Unicast, .Group, .Broadcast:
                    if params!.nonce.type == .Device {
                        return encryptForDevice()
                    } else {
                        return encryptForUnicastOrGroupAddress()
                    }
            case .Virtual:
                return encryptForVirtualAddress()
            default:
                return nil
            }
        } else {
            return nil
        }
   }

    // MARK: - Encryption
    private func encryptForVirtualAddress() -> Data {
        //EncAccessPayload, TransMIC = AES-CCM (AppKey, Application Nonce, AccessPayload, Label UUID)
        return Data()
    }
   
    private func encryptForUnicastOrGroupAddress() -> Data {
        //EncAccessPayload, TransMIC = AES-CCM (AppKey, Application Nonce, AccessPayload)
        print("upper payload \(params!.payload.hexString())")
        print("upper key \(params!.key.hexString())")
        print("upper nonce \(params!.nonce.data.hexString())")
        return sslHelper.calculateCCM(params!.payload, withKey: params!.key, nonce: params!.nonce.data, dataSize: UInt8(params!.payload.count), andMICSize: 4)
    }
   
    private func encryptForDevice() -> Data {
        //EncAccessPayload, TransMIC = AES-CCM (DevKey, Device Nonce, AccessPayload)
        print("upper payload \(params!.payload.hexString())")
        print("upper key \(params!.key.hexString())")
        print("upper nonce \(params!.nonce.data.hexString())")
        return sslHelper.calculateCCM(params!.payload, withKey: params!.key, nonce: params!.nonce.data, dataSize: UInt8(params!.payload.count), andMICSize: 4)
    }
}
