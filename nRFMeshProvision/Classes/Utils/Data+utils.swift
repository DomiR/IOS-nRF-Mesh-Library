//
//  Data+utils.swift
//  nRFMeshProvision
//
//  Created by Mostafa Berg on 22/12/2017.
//

import Foundation

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

}
