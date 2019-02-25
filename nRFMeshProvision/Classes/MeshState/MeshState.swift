//
//  MeshState.swift
//  nRFMeshProvision
//
//  Created by Mostafa Berg on 06/03/2018.
//

import Foundation

public class MeshState: NSObject, Codable {
    public var meshName         : String
    public var provisioners     : [MeshProvisionerEntry]
    public var meshUUID         : UUID
    public var version          : String
    public var timestamp        : Date
    public var nextUnicast      : Data
    public var nodes            : [MeshNodeEntry]
    public var netKeys          : [NetworkKeyEntry]
    public var appKeys          : [AppKeyEntry]
    public var globalTTL        : Data
    public var unicastAddress   : Data
    public var schema = "http://json-schema.org/draft-04/schema#";
    public var id = "TBD";


    public func deviceKeyForUnicast(_ aUnicastAddress: Data) -> Data? {
        for aNode in nodes {
            if aNode.nodeUnicast == aUnicastAddress {
                return aNode.deviceKey
            }
        }
        return nil
    }

    public init(withName aName: String, version aVersion: String, identifier anIdentifier: UUID, timestamp aTimestamp: Date, provisionerList: [MeshProvisionerEntry], nodeList aNodeList: [MeshNodeEntry], netKeys aNetKeyList: [NetworkKeyEntry], globalTTL aTTL: UInt8, unicastAddress aUnicastAddress: Data, andAppKeys anAppKeyList: [AppKeyEntry]) {
        meshName            = aName
        version             = aVersion
        meshUUID            = anIdentifier
        timestamp           = aTimestamp
        nodes               = aNodeList
        provisioners        = provisionerList
        netKeys             = aNetKeyList
        globalTTL           = Data([aTTL])
        unicastAddress      = aUnicastAddress
        appKeys             = anAppKeyList
        nextUnicast         = Data([0x00,0x01])
    }

    public func incrementUnicastBy(_ aCount: Int) {
        var unicastData = nextUnicast
        print("Incrementing Unicast: \(nextUnicast.hexString()) by \(aCount)")
        let unicastNumber = (UInt16(unicastData[0]) << 8) | (UInt16(unicastData[1]) & 0x00FF)
        //Increment by the amount of elements added, then add one to get the next free addrses
        let newUnicastNumber = unicastNumber + UInt16(aCount)
        let newUnicastData = Data([UInt8(newUnicastNumber >> 8), UInt8(newUnicastNumber & 0x00FF)])
        nextUnicast = newUnicastData
        print("Next available unicast: \(nextUnicast.hexString())")
    }

    enum CodingKeys: String, CodingKey {
        case schema = "$schema"
        case meshName
        case provisioners
        case meshUUID
        case version
        case timestamp
        case nextUnicast
        case nodes
        case netKeys
        case appKeys
        case globalTTL
        case unicastAddress
        case id
    }

    required public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        meshName = try values.decode(String.self, forKey: .meshName)
        provisioners = try values.decode([MeshProvisionerEntry].self, forKey: .provisioners)
        meshUUID = try values.decode(UUID.self, forKey: .meshUUID)
        version = try values.decode(String.self, forKey: .version)
        if let timestampString = try? values.decode(String.self, forKey: .timestamp) {
            timestamp = Date(hexString: timestampString) ?? Date()
        } else {
            timestamp = Date();
        }
        nodes = try values.decode([MeshNodeEntry].self, forKey: .nodes)
        netKeys = try values.decode([NetworkKeyEntry].self, forKey: .netKeys)
        appKeys = try values.decode([AppKeyEntry].self, forKey: .appKeys)
        globalTTL = (try? values.decode(Data.self, forKey: .globalTTL)) ?? Data([8])
        let unicastAddressString = try values.decode(String.self, forKey: .unicastAddress)
        unicastAddress = Data(hexString: unicastAddressString) ?? Data([0x7F, 0xFF]) // must not pe present when exported from android
        schema = try values.decode(String.self, forKey: .schema)
        id = try values.decode(String.self, forKey: .id)
        
        // we calculate next available address from max node address + element count of same node
        // nextUnicast = try values.decode(Data.self, forKey: .nextUnicast) // TODO: we need to calculate this from the node list
        let nextUnicastAddress = nodes.reduce(0) { (maxAddress, node) -> UInt16 in
            return max(maxAddress, ((node.nodeUnicast?.uint16 ?? 0) + UInt16(node.elements?.count ?? 0)))
        }
        nextUnicast = Data.init(fromInt16: nextUnicastAddress)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(meshName, forKey: .meshName)
        try container.encode(provisioners, forKey: .provisioners)
        try container.encode(meshUUID, forKey: .meshUUID)
        try container.encode(version, forKey: .version)
        try container.encode(timestamp.hexString(), forKey: .timestamp)
        // try container.encode(nextUnicast, forKey: .nextUnicast)
        try container.encode(nodes, forKey: .nodes)
        try container.encode(netKeys, forKey: .netKeys)
        try container.encode(appKeys, forKey: .appKeys)
        try container.encode(globalTTL, forKey: .globalTTL)
        try container.encode(unicastAddress.hexString(), forKey: .unicastAddress)
        try container.encode(schema, forKey: .schema)
        try container.encode(id, forKey: .id)
    }
}
