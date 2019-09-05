//
//  GenericLevelStatusMessage.swift
//  nRFMeshProvision
//
//  Created by Mostafa Berg on 08/10/2018.
//

import Foundation

public struct HealthAttentionStatusMessage {
    public var sourceAddress: Data
    public var attention: Data
    
    public init(withPayload aPayload: Data, andSourceAddress srcAddress: Data) {
        sourceAddress = srcAddress
        attention = Data([aPayload[0]])
    }
}
