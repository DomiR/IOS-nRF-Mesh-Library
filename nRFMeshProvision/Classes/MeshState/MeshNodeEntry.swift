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
    public let provisionedTimeStamp: Date?
    public let nodeId: Data
    public let deviceKey: Data
    public var appKeys: [Data]
    public var nodeUnicast: Data?

    // MARK: - Todo

    public var security = "low"
    public var netKeys: [Data]?
    public var configComplete = false
    public var ttl = Data([0x00, 0x05])
    public var blacklisted: Bool? = false;

    // MARK: -  Node composition

    public var companyIdentifier: Data?
    public var productIdentifier: Data?
    public var productVersion: Data?
    public var replayProtectionCount: Data?
    public var featureFlags: Data?
    public var elements: [CompositionElement]?

    // MARK: - Initialization

    public init(withName aName: String, provisionDate aProvisioningTimestamp: Date, nodeId anId: Data, andDeviceKey aDeviceKey: Data, andNetKeyIndex aNetKeyIdx: Data) {
        nodeName = aName
        provisionedTimeStamp = aProvisioningTimestamp
        nodeId = anId
        UUID = anId.hexString();
        deviceKey = aDeviceKey
        appKeys = [Data]()
        netKeys = [aNetKeyIdx]
    }

    public func getElementIndex(withUnicast elementAddress: Data) -> Int? {
        if let nodeUnicastAddress = self.nodeUnicast {
            if let elements = self.elements {
                return elements.index(where: { (element) -> Bool in
                    if let elementIndex = element.index {
                        return (nodeUnicastAddress.uint16BigEndian + UInt16(elementIndex)) == elementAddress.uint16BigEndian;
                    }
                    return false
                })
            }
        }
        return nil;
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
        case defaultTTL
        case blacklisted
        case excluded
    }

    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let UUID = try values.decode(String.self, forKey: .UUID)
        self.UUID = UUID;
        let deviceKeyString = try values.decode(String.self, forKey: .deviceKey)
        deviceKey = Data(hexString: deviceKeyString) ?? OpenSSLHelper().generateRandom()
        let nodeUnicastString = try values.decode(String.self, forKey: .nodeUnicast)
        nodeUnicast = Data(hexString: nodeUnicastString) ?? Data([0x00, 0x00])
        nodeName = try values.decode(String.self, forKey: .nodeName)
        let companyIdentifierString = try values.decodeIfPresent(String.self, forKey: .companyIdentifier)
        if let companyIdentifier = companyIdentifierString {
            self.companyIdentifier = Data(hexString: companyIdentifier)
        }
        let productIdentifierString = try values.decodeIfPresent(String.self, forKey: .productIdentifier)
        if let productIdentifier = productIdentifierString {
            self.productIdentifier = Data(hexString: productIdentifier)
        }

        let productVersionString = try values.decodeIfPresent(String.self, forKey: .productVersion)
        if let productVersion = productVersionString {
            self.productVersion = Data(hexString: productVersion)
        }
        provisionedTimeStamp = try values.decodeIfPresent(Date.self, forKey: .provisionedTimeStamp) // TODO: use android ait
        //let nodeId = try? values.decode(Data.self, forKey: .nodeId)
        self.nodeId = (Data(hexString: (UUID)) ?? Data())
        do {
          let appKeysList = try values.decode([AppKeyIndex].self, forKey: .appKeys)
          appKeys = appKeysList.compactMap { Data(hexString: $0.index) }
        } catch {
          let appKeyUInt16List = try values.decode([AppKeyIndexUInt16].self, forKey: .appKeys)
          appKeys = appKeyUInt16List.compactMap { Data(fromInt16: $0.index) }
        }

        let replayProtectionCountString = try values.decodeIfPresent(String.self, forKey: .replayProtectionCount)
        if let replayProtectionCount = replayProtectionCountString {
                self.replayProtectionCount = Data(hexString: replayProtectionCount)
        }


        let features = try values.decodeIfPresent(Features.self, forKey: .featureFlags)
        if let featureList = features {
            featureFlags = featureList.asData();
        }

        elements = try values.decode([CompositionElement].self, forKey: .elements)
        let netKeysList = try values.decode([NetKeyIndex].self, forKey: .netKeys)
        netKeys = netKeysList.map { Data(fromInt16: $0.index) }
        configComplete = try values.decode(Bool.self, forKey: .configComplete)
        let ttlInt = try values.decodeIfPresent(UInt16.self, forKey: .ttl)
        let defaultTTLInt = try values.decodeIfPresent(UInt16.self, forKey: .defaultTTL)
        ttl = ttlInt != nil ? Data(fromInt16: ttlInt!) : defaultTTLInt != nil ? Data(fromInt16: defaultTTLInt!) : Data([0x00, 0x08]);
        let blacklistedValue = try values.decodeIfPresent(Bool.self, forKey: .blacklisted)
        let excluded = try values.decodeIfPresent(Bool.self, forKey: .excluded)
        blacklisted = blacklistedValue ?? excluded ?? false;
        security = try values.decode(String.self, forKey: .security)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(UUID, forKey: .UUID)
        try container.encode(deviceKey.hexString(), forKey: .deviceKey)
        try container.encode(nodeUnicast?.hexString(), forKey: .nodeUnicast)
        try container.encode(nodeName, forKey: .nodeName)
        try container.encode(companyIdentifier?.hexString(), forKey: .companyIdentifier)
        try container.encode(productIdentifier?.hexString(), forKey: .productIdentifier)
        try container.encode(productVersion?.hexString(), forKey: .productVersion)
        try container.encodeIfPresent(provisionedTimeStamp, forKey: .provisionedTimeStamp)
        try container.encode(nodeId, forKey: .nodeId)
        try container.encode(appKeys.map { AppKeyIndex(index: $0.hexString()) }, forKey: .appKeys)
        try container.encode(replayProtectionCount?.hexString(), forKey: .replayProtectionCount)
        try container.encode(Features(withFeatureData: featureFlags), forKey: .featureFlags)
        try container.encode(elements, forKey: .elements)
        try container.encode(netKeys?.map {
            NetKeyIndex(index: $0.uint16BigEndian)
        }, forKey: .netKeys)
        try container.encode(configComplete, forKey: .configComplete)
        try container.encode(ttl.uint16BigEndian, forKey: .ttl)
        try container.encode(blacklisted, forKey: .blacklisted)
        try container.encode(security, forKey: .security)
    }
}

public struct AppKeyIndex: Codable {
    var index: String;
}

public struct AppKeyIndexUInt16: Codable {
  var index: UInt16;
}

public struct NetKeyIndex: Codable {
    var index: UInt16;
}

public enum FeatureState: UInt8, Codable {
    case disabled = 0x00;
    case enabled = 0x01;
    case unsupported = 0x02;
}

public struct Features: Codable {
    var friend: FeatureState = .disabled;
    var lowPower: FeatureState = .disabled;
    var proxy: FeatureState = .disabled;
    var relay: FeatureState = .disabled;

    private func isBitSet(b: UInt16, pos: UInt8) -> Bool {
        return (b & (1 << pos)) != 0;
    }

    public init(withFeatureData someFeatureData: Data?) {
        if let feature = someFeatureData?.uint16BigEndian {
            relay = isBitSet(b: feature, pos: 0) ? .enabled : .unsupported;
            proxy = isBitSet(b: feature, pos: 1) ? .enabled : .unsupported;
            friend = isBitSet(b: feature, pos: 2) ? .enabled : .unsupported;
            lowPower = isBitSet(b: feature, pos: 3) ? .enabled : .unsupported;
        }
    }

    public func asData() -> Data {
        var feature = UInt8(0);
        feature |= UInt8(relay == .enabled ? (1 << 0) : 0)
        feature |= UInt8(proxy == .enabled ? (1 << 1) : 0)
        feature |= UInt8(friend == .enabled ? (1 << 2) : 0)
        feature |= UInt8(lowPower == .enabled ? (1 << 3) : 0)
        return Data([feature]);
    }
}
