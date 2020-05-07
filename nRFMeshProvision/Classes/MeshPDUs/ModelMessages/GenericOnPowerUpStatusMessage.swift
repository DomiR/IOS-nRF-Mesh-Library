//
//  GenericOnPowerUpStatusMessage.swift
//  nRFMeshProvision
//

import Foundation

public struct GenericOnPowerUpStatusMessage {
    public var sourceAddress: Data
    public var onPowerUpStatus: Data

    public init(withPayload aPayload: Data, andSourceAddress srcAddress: Data) {
        sourceAddress = srcAddress
        onPowerUpStatus = Data([aPayload[0]])
    }
}
