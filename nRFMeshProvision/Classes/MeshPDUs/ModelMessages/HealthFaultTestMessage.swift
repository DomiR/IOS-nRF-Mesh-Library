//
//  HealthFaultTestMessage.swift
//  nRFMeshProvision
//

import Foundation

public struct HealthFaultTestMessage {
    var opcode  : Data
    var payload : Data
    
    public init(withTestId aTestId: Data, withCompanyId aCompanyId: Data) {
        opcode = Data([0x80, 0x32])
        payload = aTestId + aCompanyId
    }
    
    public func assemblePayload(withMeshState aState: MeshState, toAddress aDestinationAddress: Data) -> [Data]? {
        if let appKey = aState.appKeys.first?.key {
            let accessMessage = AccessMessagePDU(withPayload: payload, opcode: opcode, appKey: appKey, netKey: aState.netKeys[0].key, seq: SequenceNumber(), ivIndex: aState.netKeys[0].phase, source: aState.unicastAddress, andDst: aDestinationAddress)
            let networkPDU = accessMessage.assembleNetworkPDU()
            return networkPDU
        } else {
            print("ERROR: AppKey not present, returning nil")
            return nil
        }
        
    }
}
