//
//  TimeSetMessage.swift
//  nRFMeshProvision
//
//  Created by Dominique Rau on 18/11/2018.
//

import Foundation

public struct TimeSetMessage {
    var opcode  : Data = Data([0x5C])
    var payload : Data

    public init(withPayload aPayload: Data) {
        payload = aPayload
    }

    public func assemblePayload(withMeshState aState: MeshState, toAddress aDestinationAddress: Data) -> [Data]? {
        let appKey = aState.appKeys[0].key
        let accessMessage = AccessMessagePDU(withPayload: payload, opcode: opcode, appKey: appKey, netKey: aState.netKeys[0].key, seq: SequenceNumber(), ivIndex: aState.netKeys[0].phase, source: aState.unicastAddress, andDst: aDestinationAddress, ttl: Data([0x00]))
        let networkPDU = accessMessage.assembleNetworkPDU()
        return networkPDU
    }
}
