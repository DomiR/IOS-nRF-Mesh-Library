//
//  WhiteListMessage.swift
//  nRFMeshProvision
//
//  Created by Mostafa Berg on 08/03/2018.
//

import Foundation



public struct SegmentAcknowledgmentMessage {
    var opcode = Data([0x00])
    
    public var sourceAddress: Data
    public var payload: Data
    
    let opCode: UInt8
    
    /// Flag set to `true` if the message was sent by a Friend
    /// on behalf of a Low Power node.
    let isOnBehalfOfLowPowerNode: Bool
    /// 13 least significant bits of SeqAuth.
    let sequenceZero: UInt16
    /// Block acknowledgment for segments, bit field.
    let blockAck: UInt32
    
    public init?(withPayload aPayload: Data, andSourceAddress srcAddress: Data) {
        sourceAddress = srcAddress
        payload = aPayload
        let data = aPayload
        guard data.count == 7, data[0] & 0x80 == 0 else {
            return nil
        }
        opCode = data[0] & 0x7F
        guard opCode == 0x00 else {
            return nil
        }
        isOnBehalfOfLowPowerNode = (data[1] & 0x80) != 0
        sequenceZero = (UInt16(data[1] & 0x7F) << 6) | UInt16(data[2] >> 2)
        blockAck = CFSwapInt32BigToHost(data.read(fromOffset: 3))
        
        print("seg ack message isOnBehalfOfLowPowerNode: \(isOnBehalfOfLowPowerNode) sequenceZero: \(Data.init(fromInt16: sequenceZero).hexString()) blockAck: \(Data.init(fromInt32: blockAck).hexString())")
    }
    
    /// Returns whether the segment with given index has been received.
    ///
    /// - parameter m: The segment number.
    /// - returns: `True`, if the segment of the given number has been
    ///            acknowledged, `false` otherwise.
    func isSegmentReceived(_ m: Int) -> Bool {
        return blockAck & (1 << m) != 0
    }
    
    /// Returns whether all segments have been received.
    ///
    /// - parameter segments: The array of segments received and expected.
    /// - returns: `True` if all segments were received, `false` otherwise.
    //       func areAllSegmentsReceived(of segments: [SegmentedMessage?]) -> Bool {
    //           return areAllSegmentsReceived(lastSegmentNumber: UInt8(segments.count - 1))
    //       }
    
    /// Returns whether all segments have been received.
    ///
    /// - parameter lastSegmentNumber: The number of the last expected
    ///             segments (segN).
    /// - returns: `True` if all segments were received, `false` otherwise.
    func areAllSegmentsReceived(lastSegmentNumber: UInt8) -> Bool {
        return blockAck == (1 << (lastSegmentNumber + 1)) - 1
    }
    
    /// Whether the source Node is busy and the message should be cancelled, or not.
    var isBusy: Bool {
        return blockAck == 0
    }
}
