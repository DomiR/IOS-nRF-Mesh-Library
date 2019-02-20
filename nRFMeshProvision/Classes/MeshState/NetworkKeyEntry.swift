//
//  NetworkKeyEntry.swift
//  nRFMeshProvision
//
//  Created by Mostafa Berg on 05/12/2018.
//

import Foundation

public class NetworkKeyEntry: Codable {
    public var name         : String
    public var index        : Data
    public var key          : Data
    public var oldKey       : Data?
    public var phase        : Data
    public var flags        : Data
    public var minSecurity  : NetworkKeySecurityLevel
    public var timestamp    : Date
    
    public init(withName aName: String, andKey aKey: Data, oldKey anOldKey: Data?, atIndex anIndex: Data, atTimeStamp aTimeStamp: Date, phase aPhase: Data, andMinSecurity aMinSecurity: NetworkKeySecurityLevel) {
        name        = aName
        index       = anIndex
        key         = aKey
        oldKey      = anOldKey
        phase       = aPhase
        minSecurity = aMinSecurity
        timestamp   = aTimeStamp
        flags       = Data([0x00])
    }
    
    public init(withName aName: String, andKey aKey: Data,oldKey anOldKey: Data?, atIndex anIndex: Data, phase aPhase: Data, andMinSecurity aMinSecurity: NetworkKeySecurityLevel) {
        name        = aName
        index       = anIndex
        key         = aKey
        oldKey      = anOldKey
        phase       = aPhase
        minSecurity = aMinSecurity
        flags       = Data([0x00])
        timestamp   = Date()
    }
}

public enum NetworkKeySecurityLevel: String, Codable {
    case low   = "low"
    case high  = "high"
}
