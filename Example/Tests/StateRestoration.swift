//
//  StateRestoration.swift
//  nRFMeshProvision_Tests
//
//  Created by Mostafa Berg on 06/03/2018.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import XCTest
import nRFMeshProvision

class StateRestoration: XCTestCase {
    let testTimestamp1 = Date()
    let testTimestamp2 = Date().addingTimeInterval(10)
    let testTimestamp3 = Date().addingTimeInterval(30)
    var nodes = [MeshNodeEntry]()

    func testSerialization() {
        //Test data        
//        nodes.append(MeshNodeEntry(withName: "Node 1", provisionDate: testTimestamp1,
//                                   nodeId: Data([0xDE, 0xAD]), andDeviceKey: Data([0xBE, 0xEF])))
//        nodes.append(MeshNodeEntry(withName: "Node 2",
//                                   provisionDate: testTimestamp2, nodeId: Data([0xDE, 0xAF]),
//                                   andDeviceKey: Data([0xBE, 0xEA])))
//        nodes.append(MeshNodeEntry(withName: "Node 3",
//                                   provisionDate: testTimestamp3, nodeId: Data([0xFE, 0xAF]),
//                                   andDeviceKey: Data([0xDE, 0xEA])))
//        let appKeys = [
//            AppKeyEntry(withName: "testKey1", andKey: Data([0x00, 0x01, 0x02]), atIndex: 0),
//            AppKeyEntry(withName: "testKey1", andKey: Data([0x03, 0x04, 0x05]), atIndex: 1)
//        ]
//
//        let netKeys = [
//            NetworkKeyEntry(withName: "My Mesh", andKey: Data([0xFF, 0xAA, 0xFF]), oldKey: nil, atIndex: Data([0x0F]), atTimeStamp: Date(), phase: Data([0x12, 0x34, 0x56]), andMinSecurity: .high)
//        ]
//        
//        let state = MeshState(withName: "My Mesh", version: "1.0", identifier: UUID(), timestamp: Date(), provisionerList: [], nodeList: nodes, netKeys: netKeys, globalTTL: 0x0A, unicastAddress: Data([0x00, 0x01]), andAppKeys: appKeys)
//        //Preservation
//        let manager = MeshStateManager(withState: state)
//        manager.saveState()
//
//        //Restoration
//        XCTAssert(MeshStateManager.stateExists() == true, "Mesh state has not been stored!")
//        let anotherManager = MeshStateManager.restoreState()!
//        //Assert all properties are equal
//        XCTAssert(anotherManager.state().name == state.name, "State name did not match test data")
//        XCTAssert(anotherManager.state().globalTTL == state.globalTTL, "State TTL did not match test data")
//        XCTAssert(anotherManager.state().netKeys[0].phase == state.netKeys[0].phase, "State IVIndex did not match test data")
//        XCTAssert(anotherManager.state().netKeys[0].index == state.netKeys[0].index, "State Key Index did not match test data")
//        XCTAssert(anotherManager.state().netKeys[0].key == state.netKeys[0].key, "State NetKey did not match test data")
//        XCTAssert(anotherManager.state().unicastAddress == state.unicastAddress,
//                  "State Unicast address did not match test data")
//        XCTAssert(anotherManager.state().netKeys[0].flags == state.netKeys[0].flags, "State flags did not match test data")
//        XCTAssert(anotherManager.state().nodes.count == state.nodes.count,
//                  "State node count did not match test data")
//        //Assert appkeys are correct
//        XCTAssert(anotherManager.state().appKeys[0] == state.appKeys[0], "State AppKey 0 did not match")
//        XCTAssert(anotherManager.state().appKeys[1] == state.appKeys[1], "State AppKey 1 did not match")
//        //Assert provisioned node data is correct
//        let anotherStateNodes = anotherManager.state().nodes
//        let stateNodes = state.nodes
//        for i in 0..<nodes.count {
//            XCTAssert(anotherStateNodes[i].nodeName == stateNodes[i].nodeName, "\(i)'s name did not match")
//            XCTAssert(anotherStateNodes[i].nodeId == stateNodes[i].nodeId, "\(i)'s id did not match")
//            XCTAssert(anotherStateNodes[i].deviceKey == stateNodes[i].deviceKey, "\(i)'s devkey did not match")
//            XCTAssert(anotherStateNodes[i].provisionedTimeStamp == stateNodes[i].provisionedTimeStamp,
//                      "\(i)'s provision timestamp did not match")
//        }
   }
}
