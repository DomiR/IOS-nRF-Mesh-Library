//
//  ModelSubscriptiontionAddMessage.swift
//  nRFMeshProvision
//
//  Created by Mostafa Berg on 30/04/2018.
//
import Foundation


public struct ModelSubsriptionAddMessage {
    var opcode  : Data
    var payload : Data
    
    public init(withElementAddress anElementAddress: Data,
                subscriptionAddress aSubscriptionAddress: Data,
                andModelIdentifier aModelIdentifier: Data) {
        
        opcode = Data([0x80, 0x1B])
        payload = Data()
        payload.append(Data([anElementAddress[1], anElementAddress[0]]))
        payload.append(Data([aSubscriptionAddress[1], aSubscriptionAddress[0]]))
        if aModelIdentifier.count == 2 {
            payload.append(Data([aModelIdentifier[1], aModelIdentifier[0]]))
        } else {
            payload.append(Data([aModelIdentifier[1], aModelIdentifier[0],
                                 aModelIdentifier[3], aModelIdentifier[2]]))
        }
    }

    public func assemblePayload(withMeshState aState: MeshState, toAddress aDestinationAddress: Data) -> [Data]? {
        let deviceKey = aState.deviceKeyForUnicast(aDestinationAddress)
        if (deviceKey == nil) { return []; }
        let accessMessage = AccessMessagePDU(withPayload: payload, opcode: opcode, deviceKey: deviceKey!, netKey: aState.netKeys[0].key, seq: SequenceNumber(), ivIndex: aState.netKeys[0].phase, source: aState.unicastAddress, andDst: aDestinationAddress)
        let networkPDU = accessMessage.assembleNetworkPDU()
        return networkPDU
    }
}
