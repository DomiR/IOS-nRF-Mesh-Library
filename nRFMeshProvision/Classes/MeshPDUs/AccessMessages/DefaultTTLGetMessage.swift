//
//  DefaultTTLGetMessage.swift
//  nRFMeshProvision
//
//  Created by Mostafa Berg on 27/04/2018.
//

import Foundation

public struct DefaultTTLGetMessage {
    var opcode: Data
    var payload: Data
    public init() {
        opcode = Data([0x80, 0x0C])
        payload = Data()
    }
    
    public func assemblePayload(withMeshState aState: MeshState, toAddress aDestinationAddress: Data) -> [Data]? {
        let deviceKey = aState.deviceKeyForUnicast(aDestinationAddress)
        if (deviceKey == nil) { return []; }
        let accessMessage = AccessMessagePDU(withPayload: payload, opcode: opcode, deviceKey: deviceKey!, netKey: aState.netKeys[0].key, seq: SequenceNumber(), ivIndex: aState.netKeys[0].phase, source: aState.unicastAddress, andDst: aDestinationAddress)
        let networkPDU = accessMessage.assembleNetworkPDU()
        return networkPDU
    }
}
