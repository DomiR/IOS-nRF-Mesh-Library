//
//  TaiUtcDeltaStatusMessage.swift
//  nRFMeshProvision
//
//  Created by Dominique Rau on 18/11/2018.
//

import Foundation

public struct TaiUtcDeltaStatusMessage {
    public var sourceAddress: Data

    public let taiUtcDeltaCurrent: UInt16
    public let taiUtcDeltaNew: UInt16
    public let taiDeltaChange: UInt64


    public init?(withPayload aPayload: Data, andSourceAddress srcAddress: Data) {
        sourceAddress = srcAddress
        guard aPayload.count == 9 else {
          return nil
        }
        taiUtcDeltaCurrent = UInt16(aPayload.readBits(15, fromOffset: 0))
        taiUtcDeltaNew = UInt16(aPayload.readBits(15, fromOffset: 16))
        taiDeltaChange = aPayload.readBits(40, fromOffset: 32)
    }
}
