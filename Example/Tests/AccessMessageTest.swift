//
//  NetrokLayerTests.swift
//  nRFMeshProvision_Tests
//
//  Created by Mostafa Berg on 26/02/2018.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import XCTest
import nRFMeshProvision

class AccessMessageTests: XCTestCase {
    func testAccessMessage() {
//        let testAccessPayload = Data([0x89, 0x51, 0x1B, 0xF1, 0xD1, 0xA8, 0x1C, 0x11, 0xDC, 0xEF])
//        let ivIndex = Data([0x12, 0x34, 0x56, 0x78])
//        let testTTL = Data([0x0B])
//        let testSequence = SequenceNumber(withCount: 6)
//        let testSrc = Data([0x12, 0x01])
//        let testDst = Data([0x00, 0x03])
//        let params = LowerTransportPDUParams(withUpperTransportData: testAccessPayload,
//                                             ttl: testTTL, ctl: Data([0x00]),
//                                             ivIndex: ivIndex, sequenceNumber: testSequence,
//                                             sourceAddress: testSrc, destinationAddress: testDst,
//                                             micSize: Data([0x00]), afk: Data([0x00]),
//                                             aid: Data([0x00]), andOpcode: Data([0x80, 0x03]))
//        //expected ouptuts
//        let expectedLowerTransportData = Data([0x00, 0x89, 0x51, 0x1B, 0xF1, 0xD1, 0xA8, 0x1C, 0x11, 0xDC, 0xEF])
//        let testTransportLayer = LowerTransportLayer(withParams: params)
//
//        let pdu = testTransportLayer.createPDU()
        
        
        let payload = Data(hexString: "0000")! // value, tid
        let opcode = Data(hexString: "8203")! //
        let appKey = Data(hexString: "A9FDB9A9753573AC4E91C29F1185320E")!
        let netKey = Data(hexString: "59A81DA4FB4C8BC07AA321F5BED892BD")!
        let sequenceNumber = SequenceNumber(withTestValue: 0);
        let phase = Data(hexString: "00000000")!;
        let unicastAddress = Data(hexString: "7FF8")!
        let aDestinationAddress = Data(hexString: "0001")!
        let accessMessage = AccessMessagePDU(withPayload: payload, opcode: opcode, appKey: appKey, netKey: netKey, seq: sequenceNumber, ivIndex: phase, source: unicastAddress, andDst: aDestinationAddress)
        let networkPDU = accessMessage.assembleNetworkPDU()
        
        XCTAssert(networkPDU != nil, "Expected message");
        if let networkPDU = networkPDU {
            XCTAssert(networkPDU.count == 1, "Expected unsegmented message, received PDU with \(networkPDU.count) segments.")
            XCTAssert(networkPDU[0].hexString() == "456196BE31C4876C3B8D3D405D35804F5AD13E75C805", "Expect message to be encrypted")
        }
        
        
//        XCTAssert(pdu[0] == expectedLowerTransportData,
//                  "wrong PDU, expected 0x\(expectedLowerTransportData.hexString()), received 0x\(pdu[0])")
    }

    
}
