//
//  SchedulerStatusMessage.swift
//  nRFMeshProvision
//
//  Created by Dominique Rau on 18/11/2018.
//

import Foundation

public struct SchedulerActionStatusMessage {
    public var sourceAddress: Data
    public var index: UInt8
    public var entry: SchedulerRegistryEntry


    public init(withPayload aPayload: Data, andSourceAddress srcAddress: Data) {
        sourceAddress = srcAddress
        let encode = SchedulerRegistryEntry.unmarshal(aPayload)
        self.index = encode.index
        self.entry = encode.entry
    }
}
