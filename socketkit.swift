//
//  File.swift
//  SocketKit
//
//  Created by Pawan on 17/06/17.
//  Copyright © 2017 Pawan. All rights reserved.
//

import Foundation

open
class Server : SocketBase, ServerSocketType {
    
    // For confirming to ServerSocketType
    public
    var requestDescriptor : Int32 = 0
    public var maxNumberOfConnectionsBeforeAccept: Int32 = 20
    
    
    public var connectionQueue = DispatchQueue(
    label: "ConnectionQueue",
    qos: .utility,
    attributes: .concurrent
    )
    
    
    public
    override init() {
        super.init()
    }
    
    // ====================================
    // Bind the socket descriptor to a port
    // ====================================
    
    @objc public func Bind(){
        status = bind(
            socketDescriptor,               // The socket descriptor of the socket to bind
            servinfo!.pointee.ai_addr,        // Use the servinfo created earlier, this makes it IPv4/IPv6 independant
            servinfo!.pointee.ai_addrlen)     // Use the servinfo created earlier, this makes it IPv4/IPv6 independant
        
        print("Status from binding: \(status)")
        
        // Cop out if there is an error
        if status != 0
        {
            let strError = String(utf8String: strerror(errno)) ?? "Unknown error code"
            let message = "Binding error \(errno) (\(strError))"
            freeaddrinfo(servinfo)
            close(socketDescriptor)         // Ignore possible errors
            print (message)
            return
        }
        
        // Don't need the servinfo anymore
        freeaddrinfo(servinfo)
    }
    // ========================================
    // Start listening for incoming connections
    // ========================================
    
    public
    func Listen(){
        status = listen(/*The socket on which to listen*/socketDescriptor,/*The number of connections that will be allowed before they are accepted*/ maxNumberOfConnectionsBeforeAccept)
        print("Status from listen: " + status.description)
        
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
    
    
    // =======================================
    // Wait for an incoming connection request
    // =======================================
    
    public
    func Accept(CompletionHandler : @escaping (Int32) -> Swift.Void){
        
        // ========================
        // Start the "endless" loop
        // ========================
        
        if(!applicationInDebugMode)
        {
            ACCEPT_LOOP: while true {
                
                print("Pawan: 2")
                
                
                // =======================================
                // Wait for an incoming connection request
                // =======================================
                
                var connectedAddrInfo = sockaddr(sa_len: 0, sa_family: 0, sa_data: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0))
                var connectedAddrInfoLength = socklen_t(MemoryLayout<sockaddr>.size)
                
                requestDescriptor = accept(socketDescriptor, &connectedAddrInfo, &connectedAddrInfoLength)
                
                if requestDescriptor == -1 {
                    let strerr = String(utf8String: strerror(errno)) ?? "Unknown error code"
                    let message = "Accept error \(errno) " + strerr
                    print(message)
                    // #FEATURE# Add code to cop out if errors occur continuously
                    continue
                }
                
                
                let (ipAddress, servicePort) = getSockAddrDescription(addr: &connectedAddrInfo)
                
                let message = "Accepted connection from: " + (ipAddress ?? "nil") + ", from port:" + (servicePort ?? "nil")
                print(message)
                
                
                // ==========================================================================
                // Request processing of the connection request in a different dispatch queue
                // ==========================================================================
                
                //                var copy = self;
                //
                //                connectionQueue.async() { copy.sartReceiveAndDispatch(socket: copy.requestDescriptor)}
            }
        }
        else
        {
            // =======================================
            // Wait for an incoming connection request
            // =======================================
            
            var connectedAddrInfo = sockaddr(sa_len: 0, sa_family: 0, sa_data: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0))
            var connectedAddrInfoLength = socklen_t(MemoryLayout<sockaddr>.size)
            
            requestDescriptor = accept(socketDescriptor, &connectedAddrInfo, &connectedAddrInfoLength)
            
            if requestDescriptor == -1 {
                let strerr = String(utf8String: strerror(errno)) ?? "Unknown error code"
                let message = "Accept error \(errno) " + strerr
                print(message)
                // #FEATURE# Add code to cop out if errors occur continuously
                return
            }
            
            
            let (ipAddress, servicePort) = getSockAddrDescription(addr: &connectedAddrInfo)
            
            let message = "Accepted connection from: " + (ipAddress ?? "nil") + ", from port:" + (servicePort ?? "nil")
            print(message)
            
            
            CompletionHandler(self.requestDescriptor)
            
            
            // ==========================================================================
            // Request processing of the connection request in a different dispatch queue
            // ==========================================================================
            
            //
            //connectionQueue.async() { self.sartReceiveAndDispatch(socket: self.requestDescriptor)}
        }
        
    }
    
//    public func sartReceiveAndDispatch(socket: Int32) {
//        
//        let bufferSize = 100*1024 // Application dependant
//        
//        var requestLength: Int = 0
//        
//        func requestIsComplete() -> Bool {
//            // This function should find out if all expected data was received and return 'true' if it did.
//            return true
//        }
//        
//        func processData(data: Data, type : UInt32?) {
//            // This function should do something with the received data
//            //            let backToString = String(data: data, encoding: String.Encoding.utf8) as String!
//            //            print(backToString! + "   type: \(type!) " ?? "Nothing To Show")
//        }
//        
//        // =========================================================================================
//        // This loop stays active as long as there is data left to receive, or until an error occurs
//        // =========================================================================================
//        
//        RECEIVER_LOOP: while true {
//            // =====================================================================================
//            // Use the recv API to see what happened
//            // =====================================================================================
//            
//            var headerBuffer : Array<UInt8> = Array(repeating: 0, count: Int(headerSizeUsed))
//            let headerBytesRead = recv(
//                socket,
//                &headerBuffer,
//                Int(headerSizeUsed),
//                0)
//            
//            let packetSize : UInt32?
//            let type : UInt32?
//            
//            (packetSize, type) = decodeHeader(headerBytes: &headerBuffer)
//            
//            
//            var requestBuffer: Array<UInt8> = Array(repeating: 0, count: bufferSize)
//            
//            let bytesRead = recv(
//                socket,
//                &requestBuffer[requestLength],
//                Int(packetSize!),
//                0)
//            
//            
//            // =====================================================================================
//            // In case of an error, close the connection
//            // =====================================================================================
//            
//            if bytesRead == -1 {
//                
//                let errString = String(utf8String: strerror(errno)) ?? "Unknown error code"
//                let message = "Recv error = \(errno) (\(errString))"
//                print(message)
//                
//                // The connection might still support a transfer, it could be tried to get a message to the client. Not in this example though.
//                
//                close(socket)
//                break RECEIVER_LOOP
//            }
//            
//            
//            // =====================================================================================
//            // If the client closed the connection, close our end too
//            // =====================================================================================
//            
//            //            if bytesRead == 0 {
//            //
//            //                let message = "Client closed connection"
//            //                print(message)
//            //                close(socket)
//            //                break RECEIVER_LOOP
//            //            }
//            
//            
//            // =====================================================================================
//            // If the request is completely received, dispatch it to the dispatchQueue
//            // =====================================================================================
//            
//            if(bytesRead > 0)
//            {
//                let message = "Received \(bytesRead) bytes from the client"
//                print(message)
//            }
//            
//            
//            
//            //requestLength = requestLength + bytesRead
//            
//            if (requestIsComplete() && bytesRead > 0) {
//                
//                let receivedData = Data(bytes: requestBuffer[0 ... bytesRead])
//                processDataQueue.async() { processData(data: receivedData, type : type) }
//                
//                if(type! > 10)
//                {
//                    close(socket)
//                    break RECEIVER_LOOP
//                }
//                
//            }
//        }
//    }
}

open
class Client : SocketBase, ClientSocketType {
    
    public
    override init() {
        super.init()
    }
    
    public func Connect(){
        status = connect(socketDescriptor, servinfo?.pointee.ai_addr, (servinfo?.pointee.ai_addrlen)!)
        
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
    
    public func sartReceiveWith(completionHandler : (Data, UInt32) -> Swift.Void) {
        
        let bufferSize = 1000*1024 // Application dependant
        var requestBuffer: Array<UInt8> = Array(repeating: 0, count: bufferSize)
        var headerBuffer : Array<UInt8> = Array(repeating: 0, count: Int(headerSizeUsed))
        
        var requestLength: Int = 0
        
        func requestIsComplete() -> Bool {
            // This function should find out if all expected data was received and return 'true' if it did.
            return true
        }
        
//        func processData(data: Data, type : UInt32?) {
//            // This function should do something with the received data
////            let image = NSImage.init(data: data)
//            let backToString = String(data: data, encoding: String.Encoding.utf8) as String!
//            print(backToString! + "   type: \(type!) " ?? "Nothing To Show")
//        }
        
        // =========================================================================================
        // This loop stays active as long as there is data left to receive, or until an error occurs
        // =========================================================================================
        
        RECEIVER_LOOP: while true {
            // =====================================================================================
            // Use the recv API to see what happened
            // =====================================================================================
            
            let headerBytesRead = recv(
                self.socketDescriptor,
                &headerBuffer,
                Int(headerSizeUsed),
                0)
            
            print("headerBytesRead: \(headerBytesRead)")
            
            if(headerBytesRead < 1)
            {
                let message = "Server closed connection"
                print(message)
                close(self.socketDescriptor)
                break RECEIVER_LOOP
            }
            
            let packetSize : UInt32?
            let type : UInt32?
            
            (packetSize, type) = decodeHeader(headerBytes: &headerBuffer)
            
            
            print("PacketSizeRead: \(packetSize), typeRead: \(type)")
            
            var totalBytesRead = 0;
            requestLength = 0;
            
            while(totalBytesRead < (Int)(packetSize!))
            {
                let bytesRead = recv(
                    self.socketDescriptor,
                    &requestBuffer[requestLength],
                    Int(packetSize!) - totalBytesRead,
                    0)
                requestLength += bytesRead
                totalBytesRead += bytesRead
            }
            
            print("bytesRead: \(totalBytesRead)")
            
            // =====================================================================================
            // In case of an error, close the connection
            // =====================================================================================
            
            if totalBytesRead == -1 {
                
                let errString = String(utf8String: strerror(errno)) ?? "Unknown error code"
                let message = "Recv error = \(errno) (\(errString))"
                print(message)
                
                // The connection might still support a transfer, it could be tried to get a message to the client. Not in this example though.
                
                close(self.socketDescriptor)
                break RECEIVER_LOOP
            }
            
            
            // =====================================================================================
            // If the client closed the connection, close our end too
            // =====================================================================================
            
            //            if bytesRead == 0 {
            //
            //                let message = "Client closed connection"
            //                print(message)
            //                close(socket)
            //                break RECEIVER_LOOP
            //            }
            
            
            // =====================================================================================
            // If the request is completely received, dispatch it to the dispatchQueue
            // =====================================================================================
            
            if(totalBytesRead > 0)
            {
                let message = "Received \(totalBytesRead) bytes from the client"
                print(message)
            }
            
            
            
            //requestLength = requestLength + bytesRead
            
            if (requestIsComplete() && totalBytesRead > 0) {
                autoreleasepool{
                    var receivedData = Data(bytes: requestBuffer[0 ... totalBytesRead - 1])
                    completionHandler(receivedData, type!)
                    //processDataQueue.async() { processData(data: receivedData, type : type) }
                }
                
                if(type! > 10)
                {
                    close(self.socketDescriptor)
                    break RECEIVER_LOOP
                }
                
            }
        }
    }
}
