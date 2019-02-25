//
//  MeshNodeEntry.swift
//  nRFMeshProvision
//
//  Created by Mostafa Berg on 06/03/2018.
//

import Foundation

public class MeshNodeEntry: NSObject, Codable {
    // MARK: - Properties

    public var UUID: String?
    public let nodeName: String // TODO: investigate why correct name is not set
    public let provisionedTimeStamp: Date
    public let nodeId: Data
    public let deviceKey: Data
    public var appKeys: [Data]
    public var nodeUnicast: Data?

    // MARK: - Todo

    public var security = "low"
    public var netKeys: [Data]?
    public var configComplete = false
    public var ttl = Data([0x00, 0x05])
    public var blacklisted: Bool?

    // MARK: -  Node composition

    public var companyIdentifier: Data?
    public var productIdentifier: Data?
    public var productVersion: Data?
    public var replayProtectionCount: Data?
    public var featureFlags: Data?
    public var elements: [CompositionElement]?

    // MARK: - Initialization

    public init(withName aName: String, provisionDate aProvisioningTimestamp: Date, nodeId anId: Data, andDeviceKey aDeviceKey: Data) {
        nodeName = aName
        provisionedTimeStamp = aProvisioningTimestamp
        nodeId = anId
        UUID = anId.hexString();
        deviceKey = aDeviceKey
        appKeys = [Data]()
    }

    enum CodingKeys: String, CodingKey {
        case UUID
        case deviceKey
        case security
        case nodeUnicast = "unicastAddress"

        case nodeName = "name"
        case companyIdentifier = "cid"
        case productIdentifier = "pid"
        case productVersion = "vid"

        case provisionedTimeStamp
        case nodeId
        case appKeys
        case replayProtectionCount = "crpl"
        case featureFlags = "features"
        case elements
        case netKeys
        case configComplete
        case ttl
        case blacklisted
    }

    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        UUID = try values.decode(String.self, forKey: .UUID)
        let deviceKeyString = try values.decode(String.self, forKey: .deviceKey)
        deviceKey = Data(hexString: deviceKeyString) ?? OpenSSLHelper().generateRandom()
        let nodeUnicastString = try values.decode(String.self, forKey: .nodeUnicast)
        nodeUnicast = Data(hexString: nodeUnicastString) ?? Data([0x00, 0x00])
        nodeName = try values.decode(String.self, forKey: .nodeName)
        let companyIdentifierString = try values.decode(String.self, forKey: .companyIdentifier)
        companyIdentifier = Data(hexString: companyIdentifierString)
        let productIdentifierString = try values.decode(String.self, forKey: .productIdentifier)
        productIdentifier = Data(hexString: productIdentifierString)
        let productVersionString = try values.decode(String.self, forKey: .productVersion)
        productVersion = Data(hexString: productVersionString)
        provisionedTimeStamp = try values.decode(Date.self, forKey: .provisionedTimeStamp) // TODO: use android ait
        nodeId = try values.decode(Data.self, forKey: .nodeId)
        appKeys = try values.decode([Data].self, forKey: .appKeys)
        let replayProtectionCountString = try values.decode(String.self, forKey: .replayProtectionCount)
        replayProtectionCount = Data(hexString: replayProtectionCountString)
        featureFlags = try values.decode(Data.self, forKey: .featureFlags) // TODO: use android ait
        elements = try values.decode([CompositionElement].self, forKey: .elements)
        netKeys = try values.decode([Data].self, forKey: .netKeys)
        configComplete = try values.decode(Bool.self, forKey: .configComplete)
        let ttlInt = try values.decode(UInt16.self, forKey: .ttl)
        ttl = Data(fromInt16: ttlInt);
        blacklisted = try values.decode(Bool.self, forKey: .blacklisted)
        security = try values.decode(String.self, forKey: .security)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(UUID, forKey: .UUID)
        try container.encode(deviceKey.hexString(), forKey: .deviceKey)
        try container.encode(nodeUnicast, forKey: .nodeUnicast)
        try container.encode(nodeName, forKey: .nodeName)
        try container.encode(companyIdentifier?.hexString(), forKey: .companyIdentifier)
        try container.encode(productIdentifier?.hexString(), forKey: .productIdentifier)
        try container.encode(productVersion?.hexString(), forKey: .productVersion)
        try container.encode(provisionedTimeStamp, forKey: .provisionedTimeStamp)
        try container.encode(nodeId, forKey: .nodeId)
        try container.encode(appKeys, forKey: .appKeys)
        try container.encode(replayProtectionCount?.hexString(), forKey: .replayProtectionCount)
        try container.encode(featureFlags, forKey: .featureFlags)
        try container.encode(elements, forKey: .elements)
        try container.encode(netKeys, forKey: .netKeys)
        try container.encode(configComplete, forKey: .configComplete)
        try container.encode(ttl.uint16, forKey: .ttl)
        try container.encode(blacklisted, forKey: .blacklisted)
        try container.encode(security, forKey: .security)
    }
}
