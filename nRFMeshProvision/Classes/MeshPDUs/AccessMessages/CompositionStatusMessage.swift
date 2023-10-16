//
//  CompositionStatusMessage.swift
//  nRFMeshProvision
//
//  Created by Mostafa Berg on 03/04/2018.
//

import Foundation

public struct CompositionStatusMessage {
    public var sourceAddress: Data
    public var page: Data
    public var companyIdentifier: Data
    public var productIdentifier: Data
    public var productVersion: Data
    public var replayProtectionCount: Data
    public var features: Data
    public var elements: [CompositionElement]

    public init(withPayload aPayload: Data, andSourceAddress srcAddress: Data) {
        sourceAddress = srcAddress
        print("Create CompositionStatusMessage with \(aPayload.hexString())")
        page = Data([aPayload[0]])
        companyIdentifier = Data([aPayload[2], aPayload[1]])
        productIdentifier = Data([aPayload[4], aPayload[3]])
        productVersion  = Data([aPayload[6], aPayload[5]])
        replayProtectionCount = Data([aPayload[8], aPayload[7]])
        features = Data([aPayload[10], aPayload[9]])
        elements = [CompositionElement]()
        var allElements = Data(aPayload[11..<aPayload.count])
        var elementIdx = 0;
    
        while allElements.count > 4 {
            let elementSigCount     = Int(allElements[2])
            let elementVendorCount  = Int(allElements[3])
            //4 octets for Loc, NumS & NumV + sig (2 octets) + vendor (4 octets) offset.
            let elementEndOffset    = 4 + ((elementSigCount * 2) + elementVendorCount * 4)
            if (allElements.count >= elementEndOffset) {
                let anElementData = Data(allElements[0..<(elementEndOffset)])
                var anElement = CompositionElement(withData: anElementData)
                anElement.index = elementIdx;
                elements.append(anElement)
            }
            allElements = Data(allElements.dropFirst(elementEndOffset))
            elementIdx += 1;
        }
    }
}

