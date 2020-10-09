//
//  ModelAppStatusMessage.swift
//  nRFMeshProvision
//
//  Created by Mostafa Berg on 13/04/2018.
//

import Foundation

public struct ConfigNetworkTransmitStatusMessage {
    public var sourceAddress: Data

    public var networkTransmitCount: Int
    public var networkTransmitIntervalSteps: Int
    
    public init(withPayload aPayload: Data, andSourceAddress srcAddress: Data) {
        sourceAddress = srcAddress
        networkTransmitCount = Int(aPayload[0] & 0b111)
        networkTransmitIntervalSteps = Int(aPayload[0] >> 3 & 0b11111)

    }
    
    var debugDescription : String {
        return "sourceAddress: \(sourceAddress.hexString())\nrelayRetransmitCount:\(networkTransmitCount)\nrelayRetransmitIntervalSteps:\(networkTransmitIntervalSteps)"
    }
}
