//
//  BLOBTransferStatus.swift
//  nRFMeshProvision
//
//  Created by Mostafa Berg on 08/10/2018.
//

import Foundation

public struct BLOBTransferStatus {
    public var sourceAddress: Data
    public var payload: Data

    public init(withPayload aPayload: Data, andSourceAddress srcAddress: Data) {
        sourceAddress = srcAddress
        payload = aPayload
    }
}
