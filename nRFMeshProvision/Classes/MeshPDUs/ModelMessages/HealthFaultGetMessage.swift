//
//  HealthFaultGetMessage.swift
//  nRFMeshProvision
//
//  Created by Mostafa Berg on 08/10/2018.
//

import Foundation

public struct HealthFaultGetMessage {
    var opcode  : Data
    var payload : Data
    
    public init(withTargetState aTargetState: Data) {
        opcode = Data([0x80, 0x31])
        payload = aTargetState
    }
    
    public func assemblePayload(withMeshState aState: MeshState, toAddress aDestinationAddress: Data) -> [Data]? {
        if let appKey = aState.appKeys.first?.key {
            let accessMessage = AccessMessagePDU(withPayload: payload, opcode: opcode, appKey: appKey, netKey: aState.netKeys[0].key, seq: SequenceNumber(), ivIndex: aState.netKeys[0].phase, source: aState.unicastAddress, andDst: aDestinationAddress)
            let networkPDU = accessMessage.assembleNetworkPDU()
            return networkPDU
        } else {
            print("ERROR: AppKey not present, returning nil")
            return nil
        }
        
    }
}
