//
//  CompositionGetMessage.swift
//  nRFMeshProvision
//
//  Created by Mostafa Berg on 08/03/2018.
//

import Foundation

public struct CompositionGetMessage {
    var opcode: Data
    var payload: Data
    public init() {
        opcode = Data([0x80, 0x08])
        payload = Data([0xFF])
    }

    public func assemblePayload(withMeshState aState: MeshState, toAddress aDestinationAddress: Data) -> [Data]? {
        let deviceKey = aState.deviceKeyForUnicast(aDestinationAddress)
        print("assemble composition get for: \(aDestinationAddress.hexString()) with deviceKey: \(deviceKey?.hexString() ?? "none") and netKey: \(aState.netKeys[0].key.hexString())")
        let accessMessage = AccessMessagePDU(withPayload: payload, opcode: opcode, deviceKey: deviceKey!, netKey: aState.netKeys[0].key, seq: SequenceNumber(), ivIndex: aState.netKeys[0].phase, source: aState.unicastAddress, andDst: aDestinationAddress)
        let networkPDU = accessMessage.assembleNetworkPDU()
        return networkPDU
    }
}
