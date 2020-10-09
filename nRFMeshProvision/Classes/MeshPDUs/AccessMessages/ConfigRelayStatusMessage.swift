//
//  ModelAppStatusMessage.swift
//  nRFMeshProvision
//
//  Created by Mostafa Berg on 13/04/2018.
//

import Foundation

public struct ConfigRelayStatusMessage {
    public var sourceAddress: Data
    public var relay: Int
    public var relayRetransmitCount: Int
    public var relayRetransmitIntervalSteps: Int
    
    public init(withPayload aPayload: Data, andSourceAddress srcAddress: Data) {
        sourceAddress = srcAddress
        relay = Int(aPayload[0])
        relayRetransmitCount = Int(aPayload[1] & 0b111)
        relayRetransmitIntervalSteps = Int(aPayload[1] >> 3 & 0b11111)

    }
    
    var debugDescription : String {
        return "sourceAddress: \(sourceAddress.hexString())\nrelay:\(relay)\nrelayRetransmitCount:\(relayRetransmitCount)\nrelayRetransmitIntervalSteps:\(relayRetransmitIntervalSteps)"
    }
}
