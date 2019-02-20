//
//  MeshProvisionerEntry.swift
//  nRFMeshProvision
//
//  Created by Mostafa Berg on 05/12/2018.
//

import Foundation

public struct MeshProvisionerEntry: Codable {
    let provisionerName         : String
    let uuid                    : UUID
    let allocatedUnicastRange   : AllocatedUnicastRange
    
    init(withName aName: String, uuid aUUID: UUID, andUnicastRange aRange: AllocatedUnicastRange) {
        provisionerName         = aName
        uuid                    = aUUID
        allocatedUnicastRange   = aRange
    }
}

public struct AllocatedUnicastRange: Codable {
    let lowAddress  : String
    let highAddress : String
    
    init(withLowAddress aLowAddress: String, andHighAddress aHighAddress: String) {
        lowAddress  = aLowAddress
        highAddress = aHighAddress
    }
}
