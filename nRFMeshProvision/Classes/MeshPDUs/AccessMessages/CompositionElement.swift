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
    
    public func elementIndex() -> Int? {
        return index
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
        
        // transform model structs to internal data structure
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
                
                if let publish = model.publish {
                    if let publishAddressData = Data(hexString: publish.address) {
                        modelPublishAddress[modelId] = publishAddressData;
                    }
                }
                
                if let subscribe = model.subscribe {
                    subscribe.forEach {
                        if let subscribeAddressData = Data(hexString: $0) {
                            if var subscriptionList = modelSubscriptionAddresses[modelId] {
                                subscriptionList.append(subscribeAddressData)
                            } else {
                                modelSubscriptionAddresses[modelId] = [subscribeAddressData];
                            }
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
        var models = [MeshModel]()
        
        // transform internal structure to json
        allModels.forEach { (modelId) in
            let bind = modelKeyBindings[modelId] != nil ? [modelKeyBindings[modelId]!.hexString()] : nil;
            let subscribe = modelSubscriptionAddresses[modelId] != nil ? modelSubscriptionAddresses[modelId]!.map { $0.hexString() } : nil;
            let publish = modelPublishAddress[modelId] != nil ? PublishSettings(address: modelPublishAddress[modelId]!.hexString(), index: "0000", ttl: 0, period: 0, retransmit: PusblishRetransmitSettings(count: 0, interval: 0), credentials: 0) : nil
            models.append(MeshModel(modelId: modelId.hexString(), bind: bind, subscribe: subscribe, publish: publish))
        }
        
        try container.encode(models, forKey: .allModels)
    }
}

public struct MeshModel: Codable {
    var modelId: String
    var bind: [String]?
    var subscribe: [String]?
    var publish: PublishSettings?

    enum CodingKeys: String, CodingKey {
        case modelId, bind, subscribe, publish
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        modelId = try container.decode(String.self, forKey: .modelId)
        subscribe = try container.decodeIfPresent([String].self, forKey: .subscribe)
        publish = try container.decodeIfPresent(PublishSettings.self, forKey: .publish)

        // Try to decode bind as [String], if it fails, decode as [Int] and convert to [String]
        do {
            bind = try container.decodeIfPresent([String].self, forKey: .bind)
        } catch {
            let bindInts = try container.decodeIfPresent([UInt16].self, forKey: .bind)
          bind = bindInts?.map { Data(fromInt16: $0).hexString() }
        }
    }
  
  public init(modelId: String, bind: [String]?, subscribe: [String]?, publish: PublishSettings?) {
    self.modelId = modelId
    self.bind = bind
    self.subscribe = subscribe
    self.publish = publish
  }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(modelId, forKey: .modelId)
        try container.encodeIfPresent(bind, forKey: .bind)
        try container.encodeIfPresent(subscribe, forKey: .subscribe)
        try container.encodeIfPresent(publish, forKey: .publish)
    }
}

public struct PublishSettings: Codable {
    var address: String
    var index: String
    var ttl: Int
    var period: Int
    var retransmit: PusblishRetransmitSettings
    var credentials: Int

    enum CodingKeys: String, CodingKey {
        case address, index, ttl, period, retransmit, credentials
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        address = try container.decode(String.self, forKey: .address)
        ttl = try container.decode(Int.self, forKey: .ttl)
        retransmit = try container.decode(PusblishRetransmitSettings.self, forKey: .retransmit)
        credentials = try container.decode(Int.self, forKey: .credentials)

        // Try to decode index as String, if it fails, decode as Int and convert to String
        do {
            index = try container.decode(String.self, forKey: .index)
        } catch {
            let indexInt = try container.decode(Int.self, forKey: .index)
            index = String(indexInt)
        }
      
        // Try to decode period as number
        do {
          period = try container.decode(Int.self, forKey: .period)
        } catch {
          let periodSettings = try container.decode(PublishPeriodSettings.self, forKey: .period)
          period = periodSettings.resolution << 6 | periodSettings.numberOfSteps
        }
    }

    // New initializer
    public init(address: String, index: String, ttl: Int, period: Int, retransmit: PusblishRetransmitSettings, credentials: Int) {
        self.address = address
        self.index = index
        self.ttl = ttl
        self.period = period
        self.retransmit = retransmit
        self.credentials = credentials
    }
}

public struct PusblishRetransmitSettings: Codable {
    var count: Int
    var interval: Int
}

public struct PublishPeriodSettings: Codable {
  var numberOfSteps: Int
  var resolution: Int
}
