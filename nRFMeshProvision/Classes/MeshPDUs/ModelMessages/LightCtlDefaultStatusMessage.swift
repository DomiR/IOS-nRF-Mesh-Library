//
//  LightCtlDefaultStatusMessage.swift
//  nRFMeshProvision
//
//  Created by Dominique Rau on 18/11/2018.
//

import Foundation

public struct LightCtlDefaultStatusMessage {
    public var sourceAddress: Data
    public var defaultLightness: Data
    public var defaultTemperature: Data
    public var defaultDeltaUv: Data


    public init(withPayload aPayload: Data, andSourceAddress srcAddress: Data) {
        sourceAddress = srcAddress
        defaultLightness = Data([aPayload[0], aPayload[1]])
        defaultTemperature = Data([aPayload[2], aPayload[3]])
        defaultDeltaUv = Data([aPayload[4], aPayload[5]])
    }
}
