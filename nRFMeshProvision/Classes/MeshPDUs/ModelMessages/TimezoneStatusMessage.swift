//
//  TimezoneStatusMessage.swift
//  nRFMeshProvision
//
//  Created by Dominique Rau on 18/11/2018.
//

import Foundation

public struct TimezoneStatusMessage {
    public var sourceAddress: Data

     /// The corrent local time zone offset.
    public let currentTzOffset: UInt8
    /// The upcoming local time zone offset.
    public let nextTzOffset: UInt8
    /// The TAI seconds time when the new offset should be applied.
    public let taiSeconds: UInt64


    public init(withPayload aPayload: Data, andSourceAddress srcAddress: Data) {
        sourceAddress = srcAddress
        currentTzOffset = UInt8(aPayload.readBits(8, fromOffset: 0))
        nextTzOffset = UInt8(aPayload.readBits(8, fromOffset: 8))
        taiSeconds = aPayload.readBits(40, fromOffset: 16)
    }


}
