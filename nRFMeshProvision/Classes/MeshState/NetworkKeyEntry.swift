//
//  NetworkKeyEntry.swift
//  nRFMeshProvision
//
//  Created by Mostafa Berg on 05/12/2018.
//

import Foundation

public class NetworkKeyEntry: Codable {
    public var name: String
    public var index: Data
    public var key: Data
    public var oldKey: Data?
    public var phase: Data
    public var flags: Data
    public var minSecurity: NetworkKeySecurityLevel
    public var timestamp: Date
    
    public var beaconKey: Data?;

    public init(withName aName: String, andKey aKey: Data, oldKey anOldKey: Data?, atIndex anIndex: Data, atTimeStamp aTimeStamp: Date, phase aPhase: Data, andMinSecurity aMinSecurity: NetworkKeySecurityLevel) {
        name = aName
        index = anIndex
        key = aKey
        oldKey = anOldKey
        phase = aPhase
        minSecurity = aMinSecurity
        timestamp = aTimeStamp
        flags = Data([0x00])
        calculateDerivatives()
    }

    public init(withName aName: String, andKey aKey: Data, oldKey anOldKey: Data?, atIndex anIndex: Data, phase aPhase: Data, andMinSecurity aMinSecurity: NetworkKeySecurityLevel) {
        name = aName
        index = anIndex
        key = aKey
        oldKey = anOldKey
        phase = aPhase
        minSecurity = aMinSecurity
        flags = Data([0x00])
        timestamp = Date()
        calculateDerivatives()
    }
    
    private func calculateDerivatives() {
        let P = Data([0x69, 0x64, 0x31, 0x32, 0x38, 0x01]) // "id128" || 0x01
        let helper = OpenSSLHelper();
        let saltBK = helper.calculateSalt("nkbk".data(using: .utf8)!)
        beaconKey = OpenSSLHelper().calculateK1(withN: key, salt: saltBK, andP: P);
    }

    enum CodingKeys: String, CodingKey {
        case name
        case index
        case key
        case oldKey
        case phase
        case flags
        case minSecurity
        case timestamp
    }

    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        name = try values.decode(String.self, forKey: .name)
        let indexInt = try values.decode(UInt16.self, forKey: .index)
        index = Data(fromInt16: indexInt);
        let keyString = try values.decode(String.self, forKey: .key)
        key = Data(hexString: keyString) ?? OpenSSLHelper().generateRandom()
        if let oldKeyString = try values.decodeIfPresent(String.self, forKey: .key) {
            oldKey = Data(hexString: oldKeyString)
        }
        let phaseInt = try values.decode(UInt32.self, forKey: .phase)
        phase = Data(fromInt32: phaseInt);
        flags = try values.decodeIfPresent(Data.self, forKey: .flags) ?? Data([0x00]);
        minSecurity = try values.decode(NetworkKeySecurityLevel.self, forKey: .minSecurity)
        if let timestampString = try? values.decode(String.self, forKey: .timestamp) {
            timestamp = Date(hexString: timestampString) ?? Date();
        } else {
            timestamp = Date();
        }
        calculateDerivatives()
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(index.int16, forKey: .index)
        try container.encode(key.hexString(), forKey: .key)
        try container.encode(phase.uint32BigEndian, forKey: .phase)
        try container.encode(flags, forKey: .flags)
        try container.encode(minSecurity, forKey: .minSecurity)
        try container.encode(timestamp.hexString(), forKey: .timestamp)
        try container.encodeIfPresent(oldKey?.hexString(), forKey: .oldKey)
    }
}

public enum NetworkKeySecurityLevel: Int, Codable {
    case low = 0
    case high = 1
}
