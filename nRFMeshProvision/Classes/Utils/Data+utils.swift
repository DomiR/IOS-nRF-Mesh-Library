//
//  Data+utils.swift
//  nRFMeshProvision
//
//  Created by Mostafa Berg on 22/12/2017.
//

import Foundation

extension UInt8 {
    public func mask(bits: Int) -> UInt8 {
        if (bits == 8) {
            return self
        } else {
            return self & ((1 << bits) - 1)
        }
    }
}

public extension Data {
    //Hex string to Data representation
    //Inspired by https://stackoverflow.com/questions/26501276/converting-hex-string-to-nsdata-in-swift
    init?(hexString: String) {
        let len = hexString.count / 2
        var data = Data(capacity: len)
        for i in 0..<len {
            let j = hexString.index(hexString.startIndex, offsetBy: i*2)
            let k = hexString.index(j, offsetBy: 2)
            let bytes = hexString[j..<k]
            if var num = UInt8(bytes, radix: 16) {
                data.append(&num, count: 1)
            } else {
                return nil
            }
        }
        self = data
    }
    
   init(fromInt anInteger: Int) {
        self = Data([UInt8((anInteger & 0xFF00) >> 8), UInt8(anInteger & 0x00FF)])
    }
    
    init(fromIntAsLE anInteger: Int) {
        self = Data([UInt8(anInteger & 0x00FF), UInt8((anInteger & 0xFF00) >> 8)])
    }

    init(fromInt16 anInteger: UInt16) {
        self = Data([UInt8((anInteger & 0xFF00) >> 8), UInt8(anInteger & 0x00FF)])
    }
    
    init(fromBigInt16 anInteger: UInt16) {
        self = Data([UInt8(anInteger & 0x00FF), UInt8((anInteger & 0xFF00) >> 8)])
    }
    
    init(fromBigInt32 anInteger: UInt32) {
        self = Data([UInt8(anInteger & 0x000000FF), UInt8((anInteger & 0x0000FF00) >> 8), UInt8((anInteger & 0x00FF0000) >> 16), UInt8((anInteger & 0xFF000000) >> 24)])
    }

    init(fromInt32 anInteger: UInt32) {
        self = Data([UInt8((anInteger & 0xFF000000) >> 24), UInt8((anInteger & 0x00FF0000) >> 16), UInt8((anInteger & 0x0000FF00) >> 8), UInt8(anInteger & 0x000000FF)])
    }

    init(fromInt64 anInteger: UInt64) {
        let array: Array<UInt8> = [
            UInt8((anInteger >> 56) & 0xFF),
            UInt8((anInteger >> 48) & 0xFF),
            UInt8((anInteger >> 40) & 0xFF),
            UInt8((anInteger >> 32) & 0xFF),
            UInt8((anInteger >> 24) & 0xFF),
            UInt8((anInteger >> 16) & 0xFF),
            UInt8((anInteger >> 8) & 0xFF),
            UInt8(anInteger & 0xFF)
        ];
        self = Data(bytes: array);
    }

    func hexString() -> String {
        return self.reduce("") { string, byte in
            string + String(format: "%02X", byte)
        }
   }
    
    func bitString() -> String {
        return self.reduce("") { string, byte in
            string + String(String(String(byte, radix: 2).reversed()).padding(toLength: 8, withPad: "0", startingAt: 0).reversed()) + " ";
        }
    }
    
    func read<R: FixedWidthInteger>(fromOffset offset: Int = 0) -> R {
        let length = MemoryLayout<R>.size
        
        #if swift(>=5.0)
        return subdata(in: offset ..< offset + length).withUnsafeBytes { $0.load(as: R.self) }
        #else
        return subdata(in: offset ..< offset + length).withUnsafeBytes { $0.pointee }
        #endif
    }
    
    func readUInt24(fromOffset offset: Int = 0) -> UInt32 {
        return UInt32(self[offset]) | UInt32(self[offset + 1]) << 8 | UInt32(self[offset + 2]) << 16
    }
    
    func readBigEndian<R: FixedWidthInteger>(fromOffset offset: Int = 0) -> R {
        let r: R = read(fromOffset: offset)
        return r.bigEndian
    }

    func leftPad(length: Int) -> Data {
        guard length > self.count else {
            return self
        }
   
        let padData = Data(repeating: 0, count: length - self.count);
        return padData + self
    }

    var uint16: UInt16 {
        return withUnsafeBytes { $0.pointee }
    }

    var uint32: UInt32 {
        return withUnsafeBytes { $0.pointee }
    }

    var uint64BigEndian: UInt64 {
        return UInt64(bigEndian: withUnsafeBytes { $0.pointee })
    }

    var uint32BigEndian: UInt32 {
        return UInt32(bigEndian: withUnsafeBytes { $0.pointee })
    }
    
    var uint16BigEndian: UInt16 {
        return UInt16(bigEndian: withUnsafeBytes { $0.pointee })
    }

    var int16: Int16 {
        return withUnsafeBytes { $0.pointee }
    }

    var int16BigEndian: Int16 {
        return Int16(bigEndian: withUnsafeBytes { $0.pointee })
    }

    var int32: Int32 {
        return withUnsafeBytes { $0.pointee }
    }

    var int32BigEndian: Int32 {
        return Int32(bigEndian: withUnsafeBytes { $0.pointee })
    }
    
    /// Read a specific number of bits from an offset in the Data object.
    /// Note that this method does no sanity checks. The Data object must be large enough to read the bits.
    /// - parameters:
    ///   - numBits: The number of bits to read.
    ///   - fromOffset: The offset in bits in the Data to read from.
    func readBits(_ numBits: Int, fromOffset offset: Int) -> UInt64 {
        var res: UInt64 = 0
        
        var bitsLeft = numBits
        var currentOffset = offset % 8
        var currentShift = 0
        var bytePos = offset / 8
        
        while bitsLeft > 0 {
            let bitsFromFirstOctet = Swift.min(bitsLeft, 8 - currentOffset)
            
            if (currentOffset == 0) {
                res += UInt64(self[bytePos].mask(bits: bitsFromFirstOctet)) << currentShift
                
                currentShift += 8
                currentOffset = bitsFromFirstOctet % 8
                bytePos += 1
                bitsLeft -= 8
            } else {
                let firstOctet = (self[bytePos] >> currentOffset).mask(bits: bitsFromFirstOctet)
                
                if (bitsLeft > bitsFromFirstOctet) {
                    let bitsFromSecondOctet = Swift.min(8, bitsLeft) - bitsFromFirstOctet
                    let secondOctet = self[bytePos + 1].mask(bits: bitsFromSecondOctet) << (8 - currentOffset)
                    
                    res += UInt64(firstOctet + secondOctet) << currentShift
                    
                    currentShift += 8
                    currentOffset = bitsFromSecondOctet % 8
                    bytePos += 1
                    bitsLeft -= 8
                } else {
                    res += UInt64(firstOctet) << currentShift
                    
                    currentShift += 8
                    currentOffset = (currentOffset + bitsFromFirstOctet) % 8
                    bytePos += 1
                    bitsLeft -= bitsFromFirstOctet
                }
            }
        }
        
        return res
    }
    
    mutating func writeBits(value: UInt8, numBits: Int, atOffset offset: Int) {
        return writeBits(value: UInt64(value), numBits: numBits, atOffset: offset)
    }
    
    mutating func writeBits(value: UInt16, numBits: Int, atOffset offset: Int) {
        return writeBits(value: UInt64(value), numBits: numBits, atOffset: offset)
    }
  
    mutating func writeBits(value: Int16, numBits: Int, atOffset offset: Int) {
        return writeBits(value: UInt64(value), numBits: numBits, atOffset: offset)
    }
    
    mutating func writeBits(value: UInt32, numBits: Int, atOffset offset: Int) {
        return writeBits(value: UInt64(value), numBits: numBits, atOffset: offset)
    }
    
    /// Write a specific number of bits from a value into the Data object.
    /// Note that this method does no sanity checks, the Data must be large enough to fit the bits before calling.
    /// - parameters:
    ///   - value: The value to read bits from.
    ///   - numBits: The number of bits to write.
    ///   - atOffset: The offset in bits in the Data object to write to.
    mutating func writeBits(value: UInt64, numBits: Int, atOffset offset: Int) {
        let currentOffset = offset % 8
        var writtenBits = 0
        var bytePos = offset / 8
        
        while writtenBits < numBits {
            let bitsLeft = numBits - writtenBits
            let octet = UInt8((value >> writtenBits) & ((1 << Swift.min(bitsLeft, 8)) - 1))
            
            if (currentOffset == 0) {
                self[bytePos] = octet
                
                bytePos += 1
                writtenBits += 8
            } else {
                let bitsToFirstByte = 8 - currentOffset
                self[bytePos] = self[bytePos] | ((octet & ((1 << bitsToFirstByte) - 1)) << currentOffset)
                
                if (bitsLeft > bitsToFirstByte) {
                    self[bytePos + 1] = octet >> bitsToFirstByte
                }
                
                bytePos += 1
                writtenBits += 8
            }
        }
    }

}
