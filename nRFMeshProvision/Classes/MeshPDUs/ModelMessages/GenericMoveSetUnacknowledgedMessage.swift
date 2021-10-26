//
//  GenericMoveSetUnacknowledgedMessage.swift
//  nRFMeshProvision
//
//  Created by Dominique Rau on 18/11/2018.
//

//0x82, 0x07


import Foundation

public struct GenericMoveSetUnacknowledgedMessage {
    var opcode  : Data
    var payload : Data
    
    public init(withTargetState aTargetState: Data, transitionTime aTransitionTime: Data, andTransitionDelay aTransitionDelay: Data) {
        opcode = Data([0x82, 0x0C])
        payload = aTargetState
        //Sequence number used as TID
        let tid = Data([SequenceNumber().sequenceData().last!])
        payload.append(tid)
        payload.append(aTransitionTime)
        payload.append(aTransitionDelay)
    }
    
    public init(withTargetState aTargetState: Data) {
        opcode = Data([0x82, 0x0C])
        payload = aTargetState
        //Sequence number used as TID
        let tid = Data([SequenceNumber().sequenceData().last!])
        payload.append(tid)
    }
    
    public func assemblePayload(withMeshState aState: MeshState, toAddress aDestinationAddress: Data) -> [Data]? {
        if let appKey = aState.appKeys.first?.key {
            let accessMessage = AccessMessagePDU(withPayload: payload, opcode: opcode, appKey: appKey, netKey: aState.netKeys[0].key, seq: SequenceNumber(), ivIndex: aState.netKeys[0].phase, source: aState.unicastAddress, andDst: aDestinationAddress)
            let networkPDU = accessMessage.assembleNetworkPDU()
            return networkPDU
        } else {
            print("Error: AppKey Not present, returning nil")
            return nil
        }
    }
}
