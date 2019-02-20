//
//  AppKeyEntry.swift
//  nRFMeshProvision
//
//  Created by Mostafa Berg on 05/12/2018.
//

import Foundation

public class AppKeyEntry: Codable, Equatable {
  
    public let name        : String
    public let index       : Int
    public let boundNetKey : Int?
    public let key         : Data
    
    public init(withName aName: String, andKey aKey: Data, atIndex anIndex: Int, onNetKeyIndex aNetKeyIndex: Int? = nil) {
        name            = aName
        index           = anIndex
        key             = aKey
        boundNetKey     = aNetKeyIndex
    }
    
    // MARK: - Equatable
    public static func == (lhs: AppKeyEntry, rhs: AppKeyEntry) -> Bool {
        return lhs.boundNetKey == rhs.boundNetKey && lhs.index == rhs.index && lhs.key == rhs.key && lhs.name == rhs.name
    }
}
