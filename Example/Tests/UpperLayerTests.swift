//
//  NetrokLayerTests.swift
//  nRFMeshProvision_Tests
//
//  Created by Mostafa Berg on 26/02/2018.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import XCTest
import nRFMeshProvision

class UpperLayerTests: XCTestCase {

    func testUpperTransportEncryption() {
        //Test input
        let testAccessPayload = Data([0x00, 0x56, 0x34, 0x12, 0x63, 0x96, 0x47, 0x71, 0x73, 0x4F,
                                      0xBD, 0x76, 0xE3, 0xB4, 0x05, 0x19, 0xD1, 0xD9, 0x4A, 0x48])
        let testIVIndex = Data([0x12, 0x34, 0x56, 0x78])
        let testDeviceKey = Data([0x9D, 0x6D, 0xD0, 0xE9, 0x6E, 0xB2, 0x5D, 0xC1,
                                  0x9A, 0x40, 0xED, 0x99, 0x14, 0xF8, 0xF0, 0x3F])
        let testTTL = Data([0x04])
        let testSequence = SequenceNumber(withCount: 3221931) //0x3129AB
        let testSrc = Data([0x00, 0x03])
        let testDst = Data([0x12, 0x01])
        let testNonce = TransportNonce(deviceNonceWithIVIndex: testIVIndex,
                                       isSegmented: false,
                                       szMIC: 0,
                                       seq: testSequence.sequenceData(),
                                       src: testSrc,
                                       dst: testDst)
        
        print("testSequence \(testSequence.sequenceData().hexString())")
        print("nonce \(testNonce.data.hexString())")
        let testOpcode = Data([0x00])

        let params = UpperTransportPDUParams(withPayload: testAccessPayload,
                                             opcode: testOpcode,
                                             IVIndex: testIVIndex,
                                             key: testDeviceKey,
                                             ttl: testTTL,
                                             seq: testSequence,
                                             src: testSrc,
                                             dst: testDst,
                                             nonce: testNonce,
                                             ctl: true,
                                             afk: false, aid: Data([0x00]))
        //expected ouptuts
        let expectedEncryptedData = Data([0xEE, 0x9D, 0xDD, 0xFD, 0x21, 0x69, 0x32, 0x6D,
                                          0x23, 0xF3, 0xAF, 0xDF, 0xCF, 0xDC, 0x18, 0xC5,
                                          0x2F, 0xDE, 0xF7, 0x72, 0xE0, 0xE1, 0x73, 0x08])
        let testTransportLayer = UpperTransportLayer(withParams: params)
        guard let encData = testTransportLayer.encrypt() else {
            XCTAssert(false, "Encrypted data was not generated")
            return
        }
        XCTAssert(encData == expectedEncryptedData, "Encrypted data + MIC did not match expected value")
    }
    
    func testUpperTransortUnsegmentedAccessMessage() {
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
        let nodeEntry = MeshNodeEntry(withName: "nice", provisionDate: Date(), nodeId: Data(), andDeviceKey: Data(hexString: "DA9C4982C6273266D07A263751E4AC00")!, andNetKeyIndex:  Data([0x00, 0x00]))
        nodeEntry.nodeUnicast = Data(hexString: "0001");
        let testState = MeshState(withName: "Test Network", version: "0", identifier: UUID(), timestamp: Date.init(), provisionerList: [], nodeList: [nodeEntry], netKeys: [netKeyEntry], globalTTL: 4, unicastAddress: Data([0x7F, 0xFF]), andAppKeys: [])
        
        let testStateManager = MeshStateManager(withState: testState);
        SequenceNumber.init(withCount: 0x004655);
        var networkLayer = NetworkLayer(withStateManager: testStateManager) { (ack) -> (Void) in
            print("ack \(ack.hexString())")
        }
        networkLayer.incomingPDU(Data(hexString: "2CEA2C32DCB177AF6E389FF8C2E3F9CDB58549D100218BFB818912090B")!)
        networkLayer.incomingPDU(Data(hexString: "2C2056B7FA102AB488023474D4E10B5153C0D9490B7111D80A96F8702F")!)
        networkLayer.incomingPDU(Data(hexString: "2C4FB51AF155AF0DF65B976C3BADB263D1A99A9CB5FC7F5BC672A3E5EC")!)
        networkLayer.incomingPDU(Data(hexString: "2CA37C0C2338E9EB87CA1398929B92FC388EBEE0F82C15A520713CB520")!)
        networkLayer.incomingPDU(Data(hexString: "2CF56983BC49FF8E848BF2E5937760B4F8EB8D0311692E9F2681660CCA")!)
        networkLayer.incomingPDU(Data(hexString: "2C058809553B4C7AAC7ECB727009C3EEF339563C8ABAF59DCEF8604DC3")!)
        if let result = networkLayer.incomingPDU(Data(hexString: "2C7D71133448D1C8606630641300D9865919D2")!) {
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10.0)
    }

    func testUpperLayerFriendRequest() {
        let controlPayload  = Data([0x4B, 0x50, 0x05, 0x7E, 0x40, 0x00, 0x00, 0x01, 0x00, 0x00])
        let sequence        = SequenceNumber(withCount: 1)
        let srcAddr         = Data([0x12, 0x01])
        let dstAddr         = Data([0xFF, 0xFD])
        let netKey          = Data([0x7D, 0xD7, 0x36, 0x4C, 0xD8, 0x42, 0xAD, 0x18,
                                    0xC1, 0x7C, 0x2B, 0x82, 0x0C, 0x84, 0xC3, 0xD6])
        let ivIndex         = Data([0x12, 0x34, 0x56, 0x78])
        let opcode          = Data([0x00])


        let testNonce = TransportNonce(deviceNonceWithIVIndex: ivIndex,
                                       isSegmented: false,
                                       szMIC: 0,
                                       seq: sequence.sequenceData(),
                                       src: srcAddr,
                                       dst: dstAddr)
                print("nonce \(testNonce.data.hexString())")
        let expectedPDU = Data([0x4B, 0x50, 0x05, 0x7E, 0x40, 0x00, 0x00, 0x01, 0x00, 0x00])
        let expectedEncrypted = Data([0xBB, 0x09, 0xF0, 0xDB, 0xB4, 0xF4, 0xDD, 0xF6, 0xD0, 0x31, 0x62, 0x5A, 0x2B, 0x26])
        let upperParams = UpperTransportPDUParams(withPayload: controlPayload,
                                                  opcode: opcode,
                                                  IVIndex: ivIndex,
                                                  key: netKey,
                                                  ttl: Data([0x00]),
                                                  seq: sequence,
                                                  src: srcAddr,
                                                  dst: dstAddr,
                                                  nonce: testNonce,
                                                  ctl: true,
                                                  afk: false,
                                                  aid: Data([0x00]))

        let upperTransportLayer = UpperTransportLayer(withParams: upperParams)
        XCTAssert(expectedPDU == upperTransportLayer.rawData()!, "EXpected upper PDU did not match")
        guard let encData = upperTransportLayer.encrypt() else {
            XCTAssert(false, "Encrypted data was not generated")
            return
        }
        print("encData \(encData.hexString())")

        XCTAssert(encData == expectedEncrypted, "Encrypted data + MIC did not match expected value")
        
    }
}
