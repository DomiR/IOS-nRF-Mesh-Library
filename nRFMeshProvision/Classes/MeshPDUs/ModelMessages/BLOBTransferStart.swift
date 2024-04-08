//
//  BLOBTransferStart.swift
//  nRFMeshProvision
//
//  Created by Mostafa Berg on 08/10/2018.
//

import Foundation

public struct BLOBTransferStart {
    var opcode  : Data
    var payload : Data

    public init(withTransferMode aTransferMode: Data, withBlobId aBlobId: Data, withBlobSize aBlobSize: Data, withBlockSizeLog aBlockSizeLog: Data, andClientMTUSize aClientMTUSize: Data) {
        opcode = Data([0x83, 0x01])
        payload = aTransferMode
        payload.append(aBlobId)
        payload.append(aBlobSize)
        payload.append(aBlockSizeLog)
        payload.append(aClientMTUSize)
    }

    public func assemblePayload(withMeshState aState: MeshState, toAddress aDestinationAddress: Data) -> [Data]? {
        if let appKey = aState.appKeys.first?.key {
            let accessMessage = AccessMessagePDU(withPayload: payload, opcode: opcode, appKey: appKey, netKey: aState.netKeys[0].key, seq: SequenceNumber(), ivIndex: aState.netKeys[0].phase, source: aState.unicastAddress, andDst: aDestinationAddress)
            let networkPDU = accessMessage.assembleNetworkPDU()
            return networkPDU
        } else {
            print("Error: AppKey Not present, returning nil")
            return nil
        }
    }
}
