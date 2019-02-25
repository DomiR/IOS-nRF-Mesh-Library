//
//  CompositionElement.swift
//  nRFMeshProvision
//
//  Created by Mostafa Berg on 04/04/2018.
//

import Foundation

public struct CompositionElement: Codable {
    // MARK: - Properties

    var index: Int?
    var location: Data
    var sigModelCount: Int
    var vendorModelCount: Int
    var sigModels: [Data]
    var vendorModels: [Data]
    var allModels: [Data]
    var modelKeyBindings: [Data: Data]
    var modelPublishAddress: [Data: Data]
    var modelSubscriptionAddresses: [Data: [Data]]

    // MARK: - Initialization

    init(withData data: Data) {
        modelKeyBindings = [Data: Data]()
        modelPublishAddress = [Data: Data]()
        modelSubscriptionAddresses = [Data: [Data]]()
        location = Data([data[1], data[0]])
        sigModelCount = Int(data[2])
        vendorModelCount = Int(data[3])
        sigModels = [Data]()
        vendorModels = [Data]()
        for aSigModelIndex in 0 ..< sigModelCount {
            sigModels.append(Data([data[(2 * aSigModelIndex) + 5], data[(2 * aSigModelIndex) + 4]]))
        }
        for aVendorModelIndex in 0 ..< vendorModelCount {
            vendorModels.append(
                Data([
                    data[(2 * sigModelCount) + (4 * aVendorModelIndex) + 5],
                    data[(2 * sigModelCount) + (4 * aVendorModelIndex) + 4],
                    data[(2 * sigModelCount) + (4 * aVendorModelIndex) + 7],
                    data[(2 * sigModelCount) + (4 * aVendorModelIndex) + 6],
                ])
            )
        }
        allModels = [Data]()
        allModels.append(contentsOf: sigModels)
        allModels.append(contentsOf: vendorModels)
    }

    // MARK: - Accessors

    public func publishAddressForModelId(_ aModelId: Data) -> Data? {
        return modelPublishAddress[aModelId]
    }

    public func subscriptionAddressesForModelId(_ aModelId: Data) -> [Data]? {
        return modelSubscriptionAddresses[aModelId]
    }

    public func boundAppKeyIndexForModelId(_ aModelId: Data) -> Data? {
        return modelKeyBindings[aModelId]
    }

    public mutating func setPublishAddress(_ anAddress: Data, forModelId aModelId: Data) {
        modelPublishAddress[aModelId] = anAddress
    }

    public mutating func removeSubscriptionAddress(_ anAddress: Data, forModelId aModelId: Data) {
        if modelSubscriptionAddresses[aModelId] == nil {
            return
        }
        if let foundIndex = modelSubscriptionAddresses[aModelId]!.index(of: anAddress) {
            modelSubscriptionAddresses[aModelId]?.remove(at: foundIndex)
        }
    }

    public mutating func addSubscriptionAddress(_ anAddress: Data, forModelId aModelId: Data) {
        if modelSubscriptionAddresses[aModelId] == nil {
            modelSubscriptionAddresses[aModelId] = [Data]()
        }
        if !modelSubscriptionAddresses[aModelId]!.contains(anAddress) {
            modelSubscriptionAddresses[aModelId]!.append(anAddress)
        }
    }

    public mutating func removeKeyBinding(_: Data, forModelId aModelId: Data) {
        modelKeyBindings.removeValue(forKey: aModelId)
    }

    public mutating func setKeyBinding(_ aKey: Data, forModelId aModelId: Data) {
        modelKeyBindings.removeValue(forKey: aModelId)
        modelKeyBindings[aModelId] = aKey
    }

    public func allSigAndVendorModels() -> [Data] {
        return allModels
    }

    public func allVendorModels() -> [Data] {
        return vendorModels
    }

    public func allSigModels() -> [Data] {
        return sigModels
    }

    public func totalModelCount() -> Int {
        return allModels.count
    }

    public func elementLocation() -> Data {
        return location
    }

    enum CodingKeys: String, CodingKey {
        case index
        case location
        case allModels = "models"
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        index = try values.decode(Int.self, forKey: .index)
        let locationString = try values.decode(String.self, forKey: .location)
        location = Data(hexString: locationString) ?? Data([0x00, 0x00]);
        let models = try values.decode([MeshModel].self, forKey: .allModels);
        sigModels = [Data]()
        vendorModels = [Data]();
        modelKeyBindings = [Data: Data]()
        modelPublishAddress = [Data: Data]()
        modelSubscriptionAddresses = [Data: [Data]]()
        sigModelCount = 0
        vendorModelCount = 0
        allModels = [Data]();
        models.forEach { (model) in
            if let modelId = Data(hexString: model.modelId) {
                if (model.modelId.count == 8) {
                    vendorModels.append(modelId)
                } else {
                    sigModels.append(modelId)
                }
                // LATER: move to list of key bindings (not using only the first one)
                if let bind = model.bind {
                    if let firstBind = bind.first {
                        if let firstBindData = Data(hexString: firstBind) {
                            modelKeyBindings[modelId] = firstBindData
                        }
                    }
                }
            }
        }
        allModels.append(contentsOf: sigModels)
        allModels.append(contentsOf: vendorModels)
        sigModelCount = sigModels.count
        vendorModelCount = vendorModels.count
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(index, forKey: .index)
        try container.encode(location.hexString(), forKey: .location)
        //try container.encode(allModels, forKey: .allModels)
        var models = [MeshModel]()
        allModels.forEach { (modelId) in
            models.append(MeshModel(modelId: modelId.hexString(), bind: modelKeyBindings[modelId] != nil ? [modelKeyBindings[modelId]!.hexString()] : nil))
        }
        try container.encode(models, forKey: .allModels)
    }
}

public struct MeshModel: Codable {
    var modelId: String
    var bind: [String]?
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(modelId, forKey: .modelId)
        try container.encodeIfPresent(bind, forKey: .bind)
    }
}
