//
//  IOCommands.swift
//  SocketKit
//
//  Created by Pawan on 17/06/17.
//  Copyright © 2017 Pawan. All rights reserved.
//

import Foundation

public
protocol IOCommandHeader {
    var headerSizeUsed : UInt32 { get }
    
}

extension IOCommandHeader{
    
    public
    func decodeHeader( headerBytes : inout [UInt8]) -> (UInt32?, UInt32?){
        let packetSize = UInt32(bytes: Array(headerBytes[0..<4]))
        let type = UInt32(bytes: Array(headerBytes[4..<8]))
        return (packetSize, type)
    }
    public
    func decodeUint32( headerBytes : inout [UInt8]) -> (UInt32?){
        return UInt32(bytes: Array(headerBytes[0..<4]))
    }
    
    public
    func toByteArray<T>(_ value: T) -> [UInt8] {
        var value = value
        return withUnsafeBytes(of: &value) { Array($0) }
    }
    
    public
    func stringToByteArray(str : String) -> [UInt8] {
        return [UInt8](str.utf8);
    }
    
    public
    func fromByteArray<T>(_ value: [UInt8], _: T.Type) -> T {
        return value.withUnsafeBytes {
            $0.baseAddress!.load(as: T.self)
        }
    }
}

public
extension Data {
    
    init<T>(from value: T) {
        var value = value
        self.init(buffer: UnsafeBufferPointer(start: &value, count: 1))
    }
    
    func to<T>(type: T.Type) -> T {
        return self.withUnsafeBytes { $0.pointee }
    }
}

extension UInt16 {
    init?(bytes: [UInt8]) {
        if bytes.count != 2 {
            return nil
        }
        
        var value: UInt16 = 0
        for byte in bytes.reversed() {
            value = value << 8
            value = value | UInt16(byte)
        }
        self = value
    }
}

extension UInt32 {
    init?(bytes: [UInt8]) {
        if bytes.count != 4 {
            return nil
        }
        
        var value: UInt32 = 0
        for byte in bytes.reversed() {
            value = value << 8
            value = value | UInt32(byte)
        }
        self = value
    }
}
