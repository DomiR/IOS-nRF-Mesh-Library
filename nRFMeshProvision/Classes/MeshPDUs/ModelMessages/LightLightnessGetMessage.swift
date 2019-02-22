//
//  LightLightnessGetMessage.swift
//  nRFMeshProvision
//
//  Created by Dominique Rau on 18/11/2018.
//

import Foundation

public struct LightLightnessGetMessage {
    var opcode  : Data = Data([0x82, 0x4B])
    var payload : Data

    public init() {
        payload = Data()
    }
    
    public func assemblePayload(withMeshState aState: MeshState, toAddress aDestinationAddress: Data) -> [Data]? {
        let appKey = aState.appKeys[0].key
        let accessMessage = AccessMessagePDU(withPayload: payload, opcode: opcode, appKey: appKey, netKey: aState.netKeys[0].key, seq: SequenceNumber(), ivIndex: aState.netKeys[0].phase, source: aState.unicastAddress, andDst: aDestinationAddress)
        let networkPDU = accessMessage.assembleNetworkPDU()
        return networkPDU
    }
}
