//
//  GenericUserPropertyStatusMessage.swift
//  nRFMeshProvision
//

import Foundation

public struct GenericUserPropertyStatusMessage {
    public var sourceAddress: Data
    
    public var userPropertyKey: UInt16;
    public var access: UInt8?;
    public var data: Data?;
    
    public init(withPayload aPayload: Data, andSourceAddress srcAddress: Data) {
        sourceAddress = srcAddress
        userPropertyKey = Data([aPayload[1], aPayload[0]]).uint16;
        if (aPayload.count > 2) {
            access = UInt8(aPayload[2])
            data = Data(aPayload[3..<aPayload.count]);
        }
    }
}
