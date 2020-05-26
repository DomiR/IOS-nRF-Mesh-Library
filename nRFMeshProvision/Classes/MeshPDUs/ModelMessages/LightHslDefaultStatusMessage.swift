//
//  LightHslDefaultStatusMessage.swift
//  nRFMeshProvision
//
//  Created by Dominique Rau on 18/11/2018.
//

import Foundation

public struct LightHslDefaultStatusMessage {
    public var sourceAddress: Data
    public var defaultLightness: Data
    public var defaultHue: Data
    public var defaultSaturation: Data


    public init(withPayload aPayload: Data, andSourceAddress srcAddress: Data) {
        sourceAddress = srcAddress
        defaultLightness = Data([aPayload[0], aPayload[1]])
        defaultHue = Data([aPayload[2], aPayload[3]])
        defaultSaturation = Data([aPayload[4], aPayload[5]])
    }
}
