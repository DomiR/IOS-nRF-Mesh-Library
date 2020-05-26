//
//  LightLightnessDefaultStatusMessage.swift
//  nRFMeshProvision
//
//  Created by Dominique Rau on 18/11/2018.
//

import Foundation

public struct LightLightnessDefaultStatusMessage {
    public var sourceAddress: Data
    public var defaultLightness: Data

    public init(withPayload aPayload: Data, andSourceAddress srcAddress: Data) {
        sourceAddress = srcAddress
        defaultLightness = Data([aPayload[0], aPayload[1]])
    }
}




