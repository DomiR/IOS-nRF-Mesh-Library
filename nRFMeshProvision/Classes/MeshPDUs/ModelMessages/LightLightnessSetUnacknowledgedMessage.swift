//
//  LightLightnessSetUnacknowledgedMessage.swift
//  nRFMeshProvision
//
//  Created by Dominique Rau on 18/11/2018.
//

import Foundation

//0x82, 0x4D
public struct LightLightnessSetUnacknowledgedMessage {
    var opcode  : Data = Data([0x82, 0x4D])
    var payload : Data
    
    public init(withTargetState aTargetState: Data, transitionTime aTransitionTime: Data, andTransitionDelay aTransitionDelay: Data) {
        payload = aTargetState
        
        //Sequence number used as TID
//        let tid = Data([SequenceNumber().sequenceData().last!])
//        payload.append(tid)
        payload.append(aTransitionTime)
        payload.append(aTransitionDelay)
    }
    
    public init(withTargetState aTargetState: Data) {
        payload = aTargetState
        //Sequence number used as TID
//        let tid = Data([SequenceNumber().sequenceData().last!])
//        payload.append(tid)
    }
    
    public func assemblePayload(withMeshState aState: MeshState, toAddress aDestinationAddress: Data) -> [Data]? {
        let appKey = aState.appKeys[0].key
        print("assemble light lightness unacknowledged set: \(payload.hexString()) \(opcode.hexString()) to \(aDestinationAddress.hexString())")
        let accessMessage = AccessMessagePDU(withPayload: payload, opcode: opcode, appKey: appKey, netKey: aState.netKeys[0].key, seq: SequenceNumber(), ivIndex: aState.netKeys[0].phase, source: aState.unicastAddress, andDst: aDestinationAddress)
        let networkPDU = accessMessage.assembleNetworkPDU()
        return networkPDU
    }
}
