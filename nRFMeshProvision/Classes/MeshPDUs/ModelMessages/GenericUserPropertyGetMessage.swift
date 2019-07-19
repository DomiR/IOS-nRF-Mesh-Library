//
//  GenericUserPropertyGetMessage.swift
//  nRFMeshProvision
//

import Foundation

public struct GenericUserPropertyGetMessage {
    var opcode  : Data
    var payload : Data

    public init(withTargetState aTargetState: Data) {
        opcode = Data([0x82, 0x2F])
        payload = aTargetState
    }

    public func assemblePayload(withMeshState aState: MeshState, toAddress aDestinationAddress: Data) -> [Data]? {
        if let appKey = aState.appKeys.first?.key {
            let accessMessage = AccessMessagePDU(withPayload: payload, opcode: opcode, appKey: appKey, netKey: aState.netKeys[0].key, seq: SequenceNumber(), ivIndex: aState.netKeys[0].phase, source: aState.unicastAddress, andDst: aDestinationAddress)
            let networkPDU = accessMessage.assembleNetworkPDU()
            return networkPDU
        } else {
            print("Error: AppKey not present, returning nil")
            return nil
        }
    }
}
