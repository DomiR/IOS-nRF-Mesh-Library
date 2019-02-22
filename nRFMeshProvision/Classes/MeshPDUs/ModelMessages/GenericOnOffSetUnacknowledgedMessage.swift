//
//  GenericOnOffSetMessage.swift
//  nRFMeshProvision
//
//  Created by Mostafa Berg on 24/05/2018.
//

import Foundation

public struct GenericOnOffSetUnacknowledgedMessage {
    var opcode  : Data = Data([0x82, 0x03])
    var payload : Data
    
    public init(withTargetState aTargetState: Data, transitionTime aTransitionTime: Data, andTransitionDelay aTransitionDelay: Data) {
        payload = aTargetState
        //Sequence number used as TID
        let tid = Data([SequenceNumber().sequenceData().last!])
        payload.append(tid)
        payload.append(aTransitionTime)
        payload.append(aTransitionDelay)
    }
    
    public init(withTargetState aTargetState: Data) {
        payload = aTargetState
        //Sequence number used as TID
        let tid = Data([SequenceNumber().sequenceData().last!])
        payload.append(tid)
    }
    
    public func assemblePayload(withMeshState aState: MeshState, toAddress aDestinationAddress: Data) -> [Data]? {
        let appKey = aState.appKeys[0].key
        print("assemble generic set payload: \(payload.hexString()) \(opcode.hexString()) to: \(aDestinationAddress.hexString()) with appkey \(appKey.hexString())")
        let accessMessage = AccessMessagePDU(withPayload: payload, opcode: opcode, appKey: appKey, netKey: aState.netKeys[0].key, seq: SequenceNumber(), ivIndex: aState.netKeys[0].phase, source: aState.unicastAddress, andDst: aDestinationAddress)
        let networkPDU = accessMessage.assembleNetworkPDU()
        return networkPDU
    }
}
