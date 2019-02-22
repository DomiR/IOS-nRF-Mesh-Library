//
//  MeshNodeEntry.swift
//  nRFMeshProvision
//
//  Created by Mostafa Berg on 06/03/2018.
//

import Foundation

public class MeshNodeEntry: NSObject, Codable {

    // MARK: - Properties
    public var UUID                    : String?
    public let nodeName                : String
    public let provisionedTimeStamp    : Date
    public let nodeId                  : Data
    public let deviceKey               : Data
    public var appKeys                 : [Data]
    public var nodeUnicast             : Data?

    // MARK: - Todo
    public var security = "low"
    public var netKeys: [Data]?
    public var configComplete: Bool?
    public var ttl: Data?
    public var blacklisted: Bool?

    // MARK: -  Node composition
    public var companyIdentifier       : Data?
    public var productIdentifier       : Data?
    public var productVersion          : Data?
    public var replayProtectionCount   : Data?
    public var featureFlags            : Data?
    public var elements                : [CompositionElement]?

    // MARK: - Initialization
    public init(withName aName: String, provisionDate aProvisioningTimestamp: Date, nodeId anId: Data, andDeviceKey aDeviceKey: Data) {
        nodeName                    = aName
        provisionedTimeStamp        = aProvisioningTimestamp
        nodeId                      = anId
        deviceKey                   = aDeviceKey
        appKeys                     = [Data]()
    }

     enum CodingKeys: String, CodingKey {
        case UUID
        case deviceKey
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
}
