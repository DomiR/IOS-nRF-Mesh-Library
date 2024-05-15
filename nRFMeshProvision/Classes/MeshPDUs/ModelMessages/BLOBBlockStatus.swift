//
//  BLOBBlockGet.swift
//  nRFMeshProvision
//
//  Created by Mostafa Berg on 08/10/2018.
//

import Foundation

public struct BLOBBlockStatus {
    public var sourceAddress: Data
    public var blockStatus: Data

    public init(withPayload aPayload: Data, andSourceAddress srcAddress: Data) {
      sourceAddress = srcAddress
      blockStatus = aPayload;
    }
}
