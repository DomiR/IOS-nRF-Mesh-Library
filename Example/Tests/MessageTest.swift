//
//  NetrokLayerTests.swift
//  nRFMeshProvision_Tests
//
//  Created by Mostafa Berg on 26/02/2018.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import XCTest
import nRFMeshProvision

class MessageTests: XCTestCase {
    func testVendorMessage() {
        //let vendorMessage = VendorModelMessage(withOpcode: opcode, payload: params)
        let payload = Data(hexString: "")! // value, tid
        let opcode = Data(hexString: "C6F1F1")! //
        let appKey = Data(hexString: "A9FDB9A9753573AC4E91C29F1185320E")!
        let netKey = Data(hexString: "2778721F4C7A15E1E0E7F5F96AABF553")!
        let sequenceNumber = SequenceNumber(withTestValue: 0);
        let phase = Data(hexString: "00000000")!;
        let unicastAddress = Data(hexString: "7FFE")!
        let aDestinationAddress = Data(hexString: "0001")!
        let accessMessage = AccessMessagePDU(withPayload: payload, opcode: opcode, appKey: appKey, netKey: netKey, seq: sequenceNumber, ivIndex: phase, source: unicastAddress, andDst: aDestinationAddress)
        let networkPDU = accessMessage.assembleNetworkPDU()
        
        XCTAssert(networkPDU != nil, "Expected message");
        if let networkPDU = networkPDU {
            print("network pdu \(networkPDU[0].hexString())")
            XCTAssert(networkPDU.count == 1, "Expected unsegmented message, received PDU with \(networkPDU.count) segments.")
            XCTAssert(networkPDU[0].hexString() == "11A7D2D2CB64C9E588B74B91C6771C71F19927F375", "Expect message to be encrypted")
        }
    }

    
}
