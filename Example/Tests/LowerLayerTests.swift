//
//  NetrokLayerTests.swift
//  nRFMeshProvision_Tests
//
//  Created by Mostafa Berg on 26/02/2018.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import XCTest
import nRFMeshProvision

class LowerLayerTests: XCTestCase {


    func testDataConterter() {
        let shortMin = -32768;
        let shortMax = 32767;

        let result = Data(fromIntAsLE: shortMin);
        XCTAssert(result == Data([0x00, 0x80]))

        let resultMax = Data(fromIntAsLE : shortMax);
        XCTAssert(resultMax == Data([0xFF, 0x7F]))
//        const buffer = Buffer.from([0, 0]);
//        buffer.writeInt16LE(shortMin, 0);
//        const resultMin = buffer.toString('hex');
//        expect(resultMin).toEqual('0080');

//        buffer.writeInt16LE(shortMax, 0);
//        const resultMax = buffer.toString('hex');
//        expect(resultMax).toEqual('ff7f');
    }

    func testLowerTransportUnsegmentedAccessMessage() {
        let testAccessPayload = Data([0x89, 0x51, 0x1B, 0xF1, 0xD1, 0xA8, 0x1C, 0x11, 0xDC, 0xEF])
        let ivIndex = Data([0x12, 0x34, 0x56, 0x78])
        let testTTL = Data([0x0B])
        let testSequence = SequenceNumber(withCount: 6)
        let testSrc = Data([0x12, 0x01])
        let testDst = Data([0x00, 0x03])
        let params = LowerTransportPDUParams(withUpperTransportData: testAccessPayload,
                                             ttl: testTTL, ctl: Data([0x00]),
                                             ivIndex: ivIndex, sequenceNumber: testSequence,
                                             sourceAddress: testSrc, destinationAddress: testDst,
                                             micSize: Data([0x00]), afk: Data([0x00]),
                                             aid: Data([0x00]), andOpcode: Data([0x80, 0x03]))
        //expected ouptuts
        let expectedLowerTransportData = Data([0x00, 0x89, 0x51, 0x1B, 0xF1, 0xD1, 0xA8, 0x1C, 0x11, 0xDC, 0xEF])
        let testTransportLayer = LowerTransportLayer(withParams: params)
        let pdu = testTransportLayer.createPDU()
        XCTAssert(pdu.count == 1,
                  "Expected unsegmented message, received PDU with \(pdu.count) segments.")
        XCTAssert(pdu[0] == expectedLowerTransportData,
                  "wrong PDU, expected 0x\(expectedLowerTransportData.hexString()), received 0x\(pdu[0])")
    }

    func testLowerTransortSegmentedAccessMessage() {
        let testUpperTransportPDU = Data([0xEE, 0x9D, 0xDD, 0xFD, 0x21, 0x69, 0x32, 0x6D,
                                          0x23, 0xF3, 0xAF, 0xDF, 0xCF, 0xDC, 0x18, 0xC5,
                                          0x2F, 0xDE, 0xF7, 0x72, 0xE0, 0xE1, 0x73, 0x08])
        let ivIndex = Data([0x12, 0x34, 0x56, 0x78])
        let testSequence = SequenceNumber(withCount: 3221931) //0x3129AB
        let testTransMic = Data([0x00])
        let testTTL = Data([0x04])
        let testCtl = Data([0x00])
        let testSrc = Data([0x00, 0x03])
        let testDst = Data([0x12, 0x01])
        let params = LowerTransportPDUParams(withUpperTransportData: testUpperTransportPDU,
                                             ttl: testTTL,
                                             ctl: testCtl,
                                             ivIndex: ivIndex,
                                             sequenceNumber: testSequence,
                                             sourceAddress: testSrc,
                                             destinationAddress: testDst,
                                             micSize: testTransMic,
                                             afk: Data([0x00]),
                                             aid: Data([0x00]),
                                             andOpcode: Data([0x00]))
        let testTransportLayer = LowerTransportLayer(withParams: params)
        var expectedLowerTransportData = [Data]()
        expectedLowerTransportData.append(Data([0x80, 0x26, 0xAC, 0x01, 0xEE, 0x9D, 0xDD, 0xFD,
                                                0x21, 0x69, 0x32, 0x6D, 0x23, 0xF3, 0xAF, 0xDF]))
        expectedLowerTransportData.append(Data([0x80, 0x26, 0xAC, 0x21, 0xCF, 0xDC, 0x18, 0xC5,
                                                0x2F, 0xDE, 0xF7, 0x72, 0xE0, 0xE1, 0x73, 0x08]))
        let pdu = testTransportLayer.createPDU()
        XCTAssert(pdu.count == expectedLowerTransportData.count, "Received \(pdu.count) instead")
        XCTAssert(pdu[0] == expectedLowerTransportData[0],
                  "expected: \(expectedLowerTransportData[0].hexString()), received \(pdu[0].hexString())")
        XCTAssert(pdu[1] == expectedLowerTransportData[1],
                  "expected: \(expectedLowerTransportData[1].hexString()), received \(pdu[1].hexString())")
    }

    func testLowerTransortUnsegmentedAccessMessage() {
        let testUpperTransportPDU = Data([0xEE, 0x9D, 0xDD, 0xFD, 0x21, 0x69, 0x32, 0x6D,
                                          0x23, 0xF3, 0xAF, 0xDF, 0xCF, 0xDC, 0x18, 0xC5,
                                          0x2F, 0xDE, 0xF7, 0x72, 0xE0, 0xE1, 0x73, 0x08])

        let testPdu = Data(hexString: "002CEA2C32DCB177AF6E389FF8C2E3F9CDB58549D100218BFB818912090B")!
        let ivIndex = Data([0x12, 0x34, 0x56, 0x78])
        let testSequence = SequenceNumber(withCount: 3221931) //0x3129AB
        let testTransMic = Data([0x00])
        let testTTL = Data([0x04])
        let testCtl = Data([0x00])
        let testSrc = Data([0x00, 0x03])
        let testDst = Data([0x12, 0x01])
        let params = LowerTransportPDUParams(withUpperTransportData: testUpperTransportPDU,
                                             ttl: testTTL,
                                             ctl: testCtl,
                                             ivIndex: ivIndex,
                                             sequenceNumber: testSequence,
                                             sourceAddress: testSrc,
                                             destinationAddress: testDst,
                                             micSize: testTransMic,
                                             afk: Data([0x00]),
                                             aid: Data([0x00]),
                                             andOpcode: Data([0x00]))
        let testTransportLayer = LowerTransportLayer(withParams: params)
        let testIVIndex = Data([0x00, 0x00, 0x00, 0x00])
        let testNetKey = Data(hexString: "66E54BBA48D6992F1629A938DF13AA81")!


        let expectation = XCTestExpectation(description: "Download apple.com home page")

        let netKeyEntry = NetworkKeyEntry(withName: "Main NetKey", andKey: testNetKey, oldKey: nil, atIndex: Data([0x00, 0x00]), phase: Data([0x00, 0x00, 0x00, 0x00]), andMinSecurity: .high)
        let testState = MeshState(withName: "Test Network", version: "0", identifier: UUID(), timestamp: Date.init(), provisionerList: [], nodeList: [], netKeys: [netKeyEntry], globalTTL: 4, unicastAddress: Data([0x7F, 0xFF]), andAppKeys: [])
        
        let testStateManager = MeshStateManager(withState: testState);
        SequenceNumber.init(withCount: 0x004655);
        var networkLayer = NetworkLayer(withStateManager: testStateManager) { (ack) -> (Void) in
            print("ack \(ack.hexString())")
            expectation.fulfill()
        }
        networkLayer.incomingPDU(Data(hexString: "2CEA2C32DCB177AF6E389FF8C2E3F9CDB58549D100218BFB818912090B")!)
        networkLayer.incomingPDU(Data(hexString: "2C2056B7FA102AB488023474D4E10B5153C0D9490B7111D80A96F8702F")!)
        networkLayer.incomingPDU(Data(hexString: "2C4FB51AF155AF0DF65B976C3BADB263D1A99A9CB5FC7F5BC672A3E5EC")!)
        networkLayer.incomingPDU(Data(hexString: "2CA37C0C2338E9EB87CA1398929B92FC388EBEE0F82C15A520713CB520")!)
        networkLayer.incomingPDU(Data(hexString: "2CF56983BC49FF8E848BF2E5937760B4F8EB8D0311692E9F2681660CCA")!)

        wait(for: [expectation], timeout: 10.0)
    }

    func testLowerLayerFriendRequest() {
        let controlPayload  = Data([0x4B, 0x50, 0x05, 0x7E, 0x40, 0x00, 0x00, 0x01, 0x00, 0x00])
        let sequence        = SequenceNumber(withCount: 1)
        let srcAddr         = Data([0x12, 0x01])
        let dstAddr         = Data([0xFF, 0xFD])
        let netKey          = Data([0x7D, 0xD7, 0x36, 0x4C, 0xD8, 0x42, 0xAD, 0x18, 0xC1, 0x7C,
                                    0x2B, 0x82, 0x0C, 0x84, 0xC3, 0xD6])
        let ivIndex         = Data([0x12, 0x34, 0x56, 0x78])
        let opcode          = Data([0x03])
        let testNonce       = TransportNonce(deviceNonceWithIVIndex: ivIndex, isSegmented: false,
                                             szMIC: 0, seq: sequence.sequenceData(), src: srcAddr, dst: dstAddr)
        let expectedLowerPDU = Data([0x03, 0x4B, 0x50, 0x05, 0x7E, 0x40, 0x00, 0x00, 0x01, 0x00, 0x00])
        let upperParams = UpperTransportPDUParams(withPayload: controlPayload, opcode: opcode,
                                                  IVIndex: ivIndex, key: netKey, ttl: Data([0x00]),
                                                  seq: sequence, src: srcAddr, dst: dstAddr,
                                                  nonce: testNonce, ctl: true, afk: false, aid: Data([0x00]))
        let upperTransportLayer = UpperTransportLayer(withParams: upperParams)
        let upperTransportPDU = upperTransportLayer.rawData()!
        let lowerParams = LowerTransportPDUParams(withUpperTransportData: upperTransportPDU,
                                                  ttl: Data([0x00]), ctl: Data([0x01]),
                                                  ivIndex: ivIndex, sequenceNumber: sequence,
                                                  sourceAddress: srcAddr, destinationAddress: dstAddr,
                                                  micSize: Data([0x01]), afk: Data([0x00]),
                                                  aid: Data([0x00]), andOpcode: opcode)
        let lowerLayer = LowerTransportLayer(withParams: lowerParams)
        let lowerPDU = lowerLayer.createPDU()
        XCTAssert(expectedLowerPDU == lowerPDU[0],
                  "Expected Lower PDU: 0x\(expectedLowerPDU.hexString()),Git: 0x\(lowerPDU[0].hexString())")
    }
}
