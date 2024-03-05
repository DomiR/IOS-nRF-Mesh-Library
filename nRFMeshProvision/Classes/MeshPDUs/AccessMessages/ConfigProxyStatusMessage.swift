//
//  ConfigProxyStatusMessage.swift
//  nRFMeshProvision
//
//  Created by Mostafa Berg on 13/04/2018.
//

import Foundation

public struct ConfigProxyStatusMessage {
    public var sourceAddress: Data
    public var proxy: Int

    public init(withPayload aPayload: Data, andSourceAddress srcAddress: Data) {
        sourceAddress = srcAddress
        proxy = Int(aPayload[0])
    }

    var debugDescription : String {
        return "sourceAddress: \(sourceAddress.hexString())\nrelay:\(proxy)"
    }
}
