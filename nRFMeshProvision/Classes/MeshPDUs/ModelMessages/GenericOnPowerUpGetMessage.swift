//
//  GenericOnPowerUpGetMessage.swift
//  nRFMeshProvision
//

import Foundation

public struct GenericOnPowerUpGetMessage {
    var opcode  : Data
    var payload : Data

    public init() {
        opcode = Data([0x82, 0x11])
        payload = Data()
    }

    public func assemblePayload(withMeshState aState: MeshState, toAddress aDestinationAddress: Data) -> [Data]? {
        if let appKey = aState.appKeys.first?.key {
            print("assemble generic get payload: \(payload.hexString()) \(opcode.hexString()) to: \(aDestinationAddress.hexString()) with appkey \(appKey.hexString())")
            let accessMessage = AccessMessagePDU(withPayload: payload, opcode: opcode, appKey: appKey, netKey: aState.netKeys[0].key, seq: SequenceNumber(), ivIndex: aState.netKeys[0].phase, source: aState.unicastAddress, andDst: aDestinationAddress)
            let networkPDU = accessMessage.assembleNetworkPDU()
            return networkPDU
        } else {
            print("Error: AppKey not present, returning nil")
            return nil
        }
    }
}
