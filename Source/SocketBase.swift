//
//  File.swift
//  SocketKit
//
//  Created by Pawan on 18/06/17.
//  Copyright © 2017 Pawan. All rights reserved.
//

import Foundation

let bufferSize = 1000*1024
let headerSize = 8

open
class SocketBase : BaseProtocolForSocket{
    
    public var applicationInDebugMode : Bool = true
    public var socketDescriptor : Int32 = 0
    public var serviceAddress: String = "localhost"
    public var servicePortNumber : String = "0000"
    // General purpose status variable, used to detect error returns from socket functions
    public var status: Int32 = 0
    // For the information needed to create a socket (result from the getaddrinfo)
    public var servinfo: UnsafeMutablePointer<addrinfo>? = nil
    
    public var processDataQueue = DispatchQueue(
    label: "processDataQueue",
    qos: .utility
    )
    
    public var headerSizeUsed : UInt32 = 8
    
    var requestBuffer: Array<UInt8> = Array(repeating: 0, count: bufferSize)
    var headerBuffer : Array<UInt8> = Array(repeating: 0, count: headerSize)
    
    init() {
        
    }
    
    public func setupWith(address : String, andPortNumber : String){
        servicePortNumber = andPortNumber
        serviceAddress = address
        
        socketDescriptor = 0
        status = 0;
        servinfo = nil
        
        initializeServiceInfo();
        createSocketDescriptor();
        setSocketOptions();
        
    }
    
    public func initializeServiceInfo(){
        var hints = addrinfo(
            ai_flags: AI_PASSIVE,       // Assign the address of the local host to the socket structures
            ai_family: AF_UNSPEC,       // Either IPv4 or IPv6
            ai_socktype: SOCK_STREAM,   // TCP
            ai_protocol: 0,
            ai_addrlen: 0,
            ai_canonname: nil,
            ai_addr: nil,
            ai_next: nil)
        
        // Get the info we need to create our socket descriptor
        
        status = getaddrinfo(
            serviceAddress,                        // Any interface
            servicePortNumber,          // The port on which will be listenend
            &hints,                     // Protocol configuration as per above
            &servinfo)                  // The created information
        
        
        // Cop out if there is an error
        
        if status != 0
        {
            var strError: String
            if status == EAI_SYSTEM
            {
                strError = String(validatingUTF8: strerror(errno)) ?? "Unknown error code"
            }
            else
            {
                strError = String(validatingUTF8: gai_strerror(status)) ?? "Unknown error code"
            }
            print(strError)
            
        }
        else
        {
            // Print a list of the found IP addresses
            
            if applicationInDebugMode
            {
                var info = servinfo
                while info != nil {
                    let (clientIp, service) = getSockAddrDescription(addr: info!.pointee.ai_addr)
                    let message = "HostIp: " + (clientIp ?? "?") + " at port: " + (service ?? "?")
                    print(message)
                    info = info!.pointee.ai_next
                }
            }
        }
    }
    
    
    
    
    // ============================
    // Create the socket descriptor
    // ============================
    
    public func createSocketDescriptor(){
        socketDescriptor = socket(
            servinfo!.pointee.ai_family,      // Use the servinfo created earlier, this makes it IPv4/IPv6 independant
            servinfo!.pointee.ai_socktype,    // Use the servinfo created earlier, this makes it IPv4/IPv6 independant
            servinfo!.pointee.ai_protocol)    // Use the servinfo created earlier, this makes it IPv4/IPv6 independant
        
        print("Socket value: \(socketDescriptor)")
        
        
        // Cop out if there is an error
        
        if socketDescriptor == -1 {
            let strError = String(utf8String: strerror(errno)) ?? "Unknown error code"
            let message = "Socket creation error \(errno) (\(strError))"
            freeaddrinfo(servinfo)
            print(message)
            return
        }
        
    }
    
    // ========================================================================
    // Set the socket options (specifically: prevent the "socket in use" error)
    // ========================================================================
    
    public func setSocketOptions(){
        var optval: Int = 1; // Use 1 to enable the option, 0 to disable
        
        status = setsockopt(
            socketDescriptor,               // The socket descriptor of the socket on which the option will be set
            SOL_SOCKET,                     // Type of socket options
            SO_REUSEADDR,                   // The socket option id
            &optval,                        // The socket option value
            socklen_t(MemoryLayout<Int>.size))    // The size of the socket option value
        
        if status == -1
        {
            let strError = String(utf8String: strerror(errno)) ?? "Unknown error code"
            let message = "Setsockopt error \(errno) (\(strError))"
            freeaddrinfo(servinfo)
            close(socketDescriptor)         // Ignore possible errors
            print(message)
            return
        }
    }
    
    public func readBuffer(sockDescriptor : Int32, packetSize : Int) -> Data?{
        var totalBytesRead = 0;
        var requestLength = 0;
        
        while(totalBytesRead < packetSize)
        {
            let bytesRead = recv(
                sockDescriptor,
                &requestBuffer[requestLength],
                packetSize - totalBytesRead,
                0)
            requestLength += bytesRead
            totalBytesRead += bytesRead
        }
        
        print("bytesRead: \(totalBytesRead)")
        
        
        if totalBytesRead == -1 {
            
            let errString = String(utf8String: strerror(errno)) ?? "Unknown error code"
            let message = "Recv error = \(errno) (\(errString))"
            print(message)
            
            // The connection might still support a transfer, it could be tried to get a message to the client. Not in this example though.
            
            close(self.socketDescriptor)
        }
        
        if(totalBytesRead > 0)
        {
            let message = "Received \(totalBytesRead) bytes from the client"
            print(message)
        }
        
        var receivedData :Data?
        
        if (totalBytesRead > 0) {
            receivedData = Data(bytes: requestBuffer[0 ... totalBytesRead - 1])
        }
        else{
            receivedData = nil
        }
        return receivedData
    }
    
    public func readHeader(sockDescriptor : Int32) -> (Int, Int) {
        let headerBytesRead = recv(
            sockDescriptor,
            &self.headerBuffer,
            headerSize,
            0)
        
        print("headerBytesRead: \(headerBytesRead)")
        
        if(headerBytesRead < 1)
        {
            let message = "Server closed connection"
            print(message)
            close(self.socketDescriptor)
        }
        
        let packetSize : UInt32?
        let type : UInt32?
        
        (packetSize, type) = self.decodeHeader(headerBytes: &self.headerBuffer)
        
        print("PacketSizeRead: \(packetSize), typeRead: \(type)")
        
        return ((Int)(packetSize!), (Int)(type!))
    }
    
    public func readInt32(sockDescriptor : Int32) -> (Int32) {
        let headerBytesRead = recv(
            sockDescriptor,
            &self.headerBuffer,
            4,
            0)
        
        //print("headerBytesRead: \(headerBytesRead)")
        
        if(headerBytesRead < 1)
        {
            let message = "Server closed connection"
            print(message)
            close(self.socketDescriptor)
        }
        
        return Int32(bitPattern: self.decodeUint32(headerBytes: &self.headerBuffer)!)
    }
    
    public
    func Send(requestDescriptor : Int32, payload : [UInt8], type : UInt32){
        
        //let payload = [UInt8](str.utf8)
        
        let packetSize : UInt32 = UInt32(payload.count)
        let packetSizeByteArray = toByteArray(packetSize)
        let typeByteArray = toByteArray(type)
        
        let headerBytes = packetSizeByteArray + typeByteArray
        
        //let buffer =  headerBytes + payload
        
        print("packetSize : \(packetSize), type: \(type), total: \(headerBytes.count + payload.count)");
        
        //        let packetSizeBack : UInt32?
        //        let typeBack : UInt32?
        //
        //        (packetSizeBack, typeBack) = decodeHeader(headerBytes: buffer)
        
        let bytesSend1 = send(requestDescriptor, headerBytes, headerBytes.count, 0)
        let bytesSend2 = send(requestDescriptor, payload, payload.count, 0)
        
        
        // Cop out if there are any errors
        if status != 0
        {
            let strError = String(utf8String: strerror(errno)) ?? "Unknown error code"
            let message = "Listen error \(errno) (\(strError))"
            print(message)
            close(socketDescriptor)         // Ignore possible errors
            return
        }
    }
    public
    func SendWithPossesInfo(requestDescriptor : Int32, payload : [UInt8], type : UInt32, possesInfo : PossesInfo ){
        
        //let payload = [UInt8](str.utf8)
        
        let packetSize : UInt32 = UInt32(payload.count)
        let packetSizeByteArray = toByteArray(packetSize)
        let typeByteArray = toByteArray(type)
        
        let topBytes = toByteArray(possesInfo.top)
        let leftBytes = toByteArray(possesInfo.left)
        let rightBytes = toByteArray(possesInfo.right)
        let bottomBytes = toByteArray(possesInfo.bottom)
        
        let headerBytes = packetSizeByteArray + typeByteArray
        
        //let buffer =  headerBytes + payload
        
        print("packetSize : \(packetSize), type: \(type), total: \(headerBytes.count + payload.count)");
        
        //        let packetSizeBack : UInt32?
        //        let typeBack : UInt32?
        //
        //        (packetSizeBack, typeBack) = decodeHeader(headerBytes: buffer)
        
        send(requestDescriptor, headerBytes, headerBytes.count, 0)
        
        send(requestDescriptor, topBytes, topBytes.count, 0)
        send(requestDescriptor, leftBytes, leftBytes.count, 0)
        send(requestDescriptor, rightBytes, rightBytes.count, 0)
        send(requestDescriptor, bottomBytes, bottomBytes.count, 0)
        
        send(requestDescriptor, payload, payload.count, 0)
        
        
        // Cop out if there are any errors
        if status != 0
        {
            let strError = String(utf8String: strerror(errno)) ?? "Unknown error code"
            let message = "Listen error \(errno) (\(strError))"
            print(message)
            close(socketDescriptor)         // Ignore possible errors
            return
        }
    }
}

open
class PossesInfo {
    public var top : Int32 = 0
    public var left : Int32 = 0
    public var right : Int32 = 0
    public var bottom : Int32 = 0
    
    public init(){
        
    }
}
