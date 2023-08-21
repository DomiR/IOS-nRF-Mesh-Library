//
//  TimeStatusMessage.swift
//  nRFMeshProvision
//
//  Created by Dominique Rau on 18/11/2018.
//

import Foundation

public struct TimeStatusMessage {
    public var sourceAddress: Data
    public var taiTime: TaiTime


    public init(withPayload aPayload: Data, andSourceAddress srcAddress: Data) {
        sourceAddress = srcAddress
        guard aPayload.count == 10 else {
          taiTime = TaiTime()
          return;
        }
        taiTime = TaiTime.unmarshal(aPayload)
        
    }
}
