//
//  GenericLevelSetMessage.swift
//  nRFMeshProvision
//
//  Created by Mostafa Berg on 08/10/2018.
//

import Foundation

public struct VendorModelMessage {
    var opcode  : Data
    var payload : Data
    
    public init(withOpcode aOpcode: Data, payload aPayload: Data) {
        opcode = aOpcode
        payload = aPayload
    }
    
    public func assemblePayload(withMeshState aState: MeshState, toAddress aDestinationAddress: Data) -> [Data]? {
        let deviceKey = aState.deviceKeyForUnicast(aDestinationAddress)
        let appKey = aState.appKeys[0].key;
        print("assemble vendor message: \(aDestinationAddress.hexString()) with opcode: \(opcode.hexString()) withPayload: \(payload.hexString()) with deviceKey: \(deviceKey?.hexString() ?? "none"), appKey: \(appKey.hexString()) and netKey: \(aState.netKeys[0].key.hexString()) and source: \(aState.unicastAddress.hexString())")
        let accessMessage = AccessMessagePDU(withPayload: payload, opcode: opcode, appKey: appKey, netKey: aState.netKeys[0].key, seq: SequenceNumber(), ivIndex: aState.netKeys[0].phase, source: aState.unicastAddress, andDst: aDestinationAddress)
        let networkPDU = accessMessage.assembleNetworkPDU()
        return networkPDU
    }
}
