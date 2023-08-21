//
//  TimeRoleStatusMessage.swift
//  nRFMeshProvision
//
//  Created by Dominique Rau on 18/11/2018.
//

import Foundation

public struct TimeRoleStatusMessage {
    public var sourceAddress: Data
    public var role: UInt8


    public init(withPayload aPayload: Data, andSourceAddress srcAddress: Data) {
        sourceAddress = srcAddress
        role = aPayload[0]
    }
}
