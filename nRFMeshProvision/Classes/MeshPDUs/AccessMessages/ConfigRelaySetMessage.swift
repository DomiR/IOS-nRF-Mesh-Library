//
//  ModelAppBindMessage.swift
//  nRFMeshProvision
//
//  Created by Mostafa Berg on 13/04/2018.
//

import Foundation


public struct ConfigRelaySetMessage {
    var opcode  : Data
    var payload : Data

    public init(withRelay relay: Int,
                withRelayRetransmitCount relayRetransmitCount: Int,
                withRelayRetransmitIntervalSteps relayRetransmitIntervalSteps: Int) {
        opcode = Data([0x80, 0x27])
        payload = Data([UInt8(relay & 0xff), UInt8((relayRetransmitCount & 0x07) | (relayRetransmitIntervalSteps << 3))])
    }

    public func assemblePayload(withMeshState aState: MeshState, toAddress aDestinationAddress: Data) -> [Data]? {
        let deviceKey = aState.deviceKeyForUnicast(aDestinationAddress)
        if (deviceKey == nil) { return []; }
        print("assemble set config relay payload: \(payload.hexString()) \(opcode.hexString()) to \(aDestinationAddress.hexString())")
        let accessMessage = AccessMessagePDU(withPayload: payload, opcode: opcode, deviceKey: deviceKey!, netKey: aState.netKeys[0].key, seq: SequenceNumber(), ivIndex: aState.netKeys[0].phase, source: aState.unicastAddress, andDst: aDestinationAddress)
        let networkPDU = accessMessage.assembleNetworkPDU()
        return networkPDU
    }
}
