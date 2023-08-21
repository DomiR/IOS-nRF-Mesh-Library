//
//  SchedulerStatusMessage.swift
//  nRFMeshProvision
//
//  Created by Dominique Rau on 18/11/2018.
//

import Foundation

public struct SchedulerStatusMessage {
    public var sourceAddress: Data
    public var schedulerRegister: Data
   
    public init(withPayload aPayload: Data, andSourceAddress srcAddress: Data) {
        sourceAddress = srcAddress
        schedulerRegister = Data(aPayload)
    }
}
