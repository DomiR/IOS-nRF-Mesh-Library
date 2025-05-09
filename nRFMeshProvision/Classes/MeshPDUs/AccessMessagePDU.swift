//
//  AccessMessagePDU.swift
//  nRFMeshProvision
//
//  Created by Mostafa Berg on 06/03/2018.
//

import Foundation

public class AccessMessagePDU {
    let opcode      : Data
    let payload     : Data
    let key         : Data?
    let netKey      : Data
    let isAppKey    : Bool
    let ivIndex     : Data
    let ttl         : Data
    let src         : Data
    let dst         : Data
    let seq         : SequenceNumber
    var networkLayer: NetworkLayer?
    public init(withPayload aPayload: Data, opcode anOpcode: Data, appKey anAppKey: Data, netKey aNetKey: Data, seq aSeq: SequenceNumber, ivIndex anIVIndex: Data, source aSrc: Data, andDst aDST: Data) {
        isAppKey    = true
        opcode      = anOpcode
        payload     = aPayload
        key         = anAppKey
        netKey      = aNetKey
        src         = aSrc
        dst         = aDST
        ivIndex     = anIVIndex
        seq         = aSeq
        ttl         = Data([0x08])
    }

    public init(withPayload aPayload: Data, opcode anOpcode: Data, appKey anAppKey: Data, netKey aNetKey: Data, seq aSeq: SequenceNumber, ivIndex anIVIndex: Data, source aSrc: Data, andDst aDST: Data, ttl aTTL: Data) {
        isAppKey    = true
        opcode      = anOpcode
        payload     = aPayload
        key         = anAppKey
        netKey      = aNetKey
        src         = aSrc
        dst         = aDST
        ivIndex     = anIVIndex
        seq         = aSeq
        ttl         = aTTL
    }

    public init(withPayload aPayload: Data, opcode anOpcode: Data, deviceKey aDeviceKey: Data, netKey aNetKey: Data, seq aSeq: SequenceNumber, ivIndex anIVIndex: Data, source aSrc: Data, andDst aDST: Data) {
        isAppKey    = false
        opcode      = anOpcode
        payload     = aPayload
        key         = aDeviceKey
        netKey      = aNetKey
        src         = aSrc
        dst         = aDST
        ivIndex     = anIVIndex
        seq         = aSeq
        ttl         = Data([0x08])
    }

    public init(withPayload aPayload: Data, opcode anOpcode: Data, deviceKey aDeviceKey: Data, netKey aNetKey: Data, seq aSeq: SequenceNumber, ivIndex anIVIndex: Data, source aSrc: Data, andDst aDST: Data, ttl aTTL: Data) {
        isAppKey    = false
        opcode      = anOpcode
        payload     = aPayload
        key         = aDeviceKey
        netKey      = aNetKey
        src         = aSrc
        dst         = aDST
        ivIndex     = anIVIndex
        seq         = aSeq
        ttl         = aTTL
    }


    public func assembleNetworkPDU() -> [Data]? {
        var nonce : TransportNonce
        let segmented = payload.count > 12
        print("""
        ==========================
        ↗️ Create Access Message PDU:
          Opcode: \(opcode.hexString())
          Payload: \(payload.hexString())
          Destination: \(self.dst.hexString())
          IV Index: \(ivIndex.hexString())
        """)
        if isAppKey {
            let addressType = MeshAddressTypes(rawValue: Data(dst))!
            if addressType != .Unassigned {
                nonce = TransportNonce(appNonceWithIVIndex: ivIndex, isSegmented: segmented, seq: seq.sequenceData(), src: src, dst: dst)
            } else {
                print("Unassigned cannot be used for Application messages")
                return nil
            }
        } else {
            let addressType = MeshAddressTypes(rawValue: Data(dst))!
            if addressType == .Unassigned { //This is a proxy nonce message since destination is an unassigned address
                nonce = TransportNonce(proxyNonceWithIVIndex: ivIndex, seq: seq.sequenceData(), src: src)
            } else if addressType == .Unicast {
                nonce = TransportNonce(deviceNonceWithIVIndex: ivIndex, isSegmented: segmented, szMIC: 0, seq: seq.sequenceData(), src: src, dst: dst)
            } else {
                nonce = TransportNonce(networkNonceWithIVIndex: ivIndex, ctl: Data([0x00]), ttl: ttl, seq: seq.sequenceData(), src: src)
            }
        }

        var upperTransportParams: UpperTransportPDUParams!

        if nonce.type == .Device {
            upperTransportParams = UpperTransportPDUParams(withPayload: Data(opcode + payload), opcode: opcode, IVIndex: ivIndex, key: key!, ttl: ttl, seq: seq, src: src, dst: dst, nonce: nonce, ctl: false, afk: isAppKey, aid: Data([0x00]))
        } else {
            let sslHelper = OpenSSLHelper()
            let aid = sslHelper.calculateK4(withN: key!)

            upperTransportParams = UpperTransportPDUParams(withPayload: Data(opcode + payload), opcode: opcode, IVIndex: ivIndex, key: key!, ttl: ttl, seq: seq, src: src, dst: dst, nonce: nonce, ctl: false, afk: isAppKey, aid: aid!)
        }

        let upperTransport = UpperTransportLayer(withParams: upperTransportParams)

        if let encryptedPDU = upperTransport.encrypt() {
            let isAppKeyData = isAppKey ? Data([0x01]) : Data([0x00])
            let lowerTransportParams = LowerTransportPDUParams(withUpperTransportData: Data(encryptedPDU), ttl: ttl, ctl: Data([0x00]), ivIndex: ivIndex, sequenceNumber: seq, sourceAddress: src, destinationAddress: dst, micSize: Data([0x00]), afk: isAppKeyData, aid: upperTransport.params!.aid, andOpcode: opcode)
            let lowerTransport = LowerTransportLayer(withParams: lowerTransportParams)
            networkLayer = NetworkLayer(withLowerTransportLayer: lowerTransport, andNetworkKey: netKey)
            let lowerPDU = lowerTransport.createPDU()
            return networkLayer!.createPDU(withLowerPdus: lowerPDU)
        } else {
            return nil
        }
   }
}
