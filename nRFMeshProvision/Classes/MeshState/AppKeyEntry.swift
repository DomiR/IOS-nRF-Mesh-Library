//
//  AppKeyEntry.swift
//  nRFMeshProvision
//
//  Created by Mostafa Berg on 05/12/2018.
//

import Foundation

public class AppKeyEntry: Codable, Equatable {
    public let name: String
    public let index: Int
    public let boundNetKey: Int?
    public var key: Data

    public init(withName aName: String, andKey aKey: Data, atIndex anIndex: Int, onNetKeyIndex aNetKeyIndex: Int? = nil) {
        name = aName
        index = anIndex
        key = aKey
        boundNetKey = aNetKeyIndex
    }

    // MARK: - Equatable

    public static func == (lhs: AppKeyEntry, rhs: AppKeyEntry) -> Bool {
        return lhs.boundNetKey == rhs.boundNetKey && lhs.index == rhs.index && lhs.key == rhs.key && lhs.name == rhs.name
    }

    enum CodingKeys: String, CodingKey {
        case name
        case index
        case boundNetKey
        case key
    }

    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        name = try values.decode(String.self, forKey: .name)
        index = try values.decode(Int.self, forKey: .index)
        boundNetKey = try values.decodeIfPresent(Int.self, forKey: .boundNetKey) ?? 0
        let keyString = try values.decode(String.self, forKey: .key)
        key = Data(hexString: keyString) ?? OpenSSLHelper().generateRandom()
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(index, forKey: .index)
        try container.encode(boundNetKey, forKey: .boundNetKey)
        try container.encode(key.hexString(), forKey: .key)
    }
}
