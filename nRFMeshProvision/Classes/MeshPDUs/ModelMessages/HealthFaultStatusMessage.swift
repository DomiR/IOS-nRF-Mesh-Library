//
//  HealthFaultStatusMessage.swift
//  nRFMeshProvision
//
//  Created by Mostafa Berg on 08/10/2018.
//

import Foundation

public struct HealthFaultStatusMessage {
    public var sourceAddress: Data
    public var testId: Data
    public var companyId: Data
    public var faultArray: Data?
    
    public init(withPayload aPayload: Data, andSourceAddress srcAddress: Data) {
        sourceAddress = srcAddress
        testId = Data([aPayload[0]])
        companyId = Data([aPayload[1],aPayload[2]]);
        if (aPayload.count > 3) {
            faultArray = Data(aPayload[3..<aPayload.count]);
        }
    }
}
