//
//  SocketBase.swift
//  SocketKit
//
//  Created by Pawan on 17/06/17.
//  Copyright © 2017 Pawan. All rights reserved.
//

import Foundation

public
protocol BaseProtocolForSocket :  IOCommandHeader {
    var applicationInDebugMode : Bool { get set }
    var socketDescriptor : Int32 { get set }
    var serviceAddress: String { get set}
    var servicePortNumber : String { get set}
    // General purpose status variable, used to detect error returns from socket functions
    var status: Int32 { get set}
    // For the information needed to create a socket (result from the getaddrinfo)
    var servinfo: UnsafeMutablePointer<addrinfo>? { get set}
    
    var processDataQueue : DispatchQueue { get set }
    
    func setupWith(address : String, andPortNumber : String)
    func initializeServiceInfo()
    func createSocketDescriptor()
    func setSocketOptions()
    
    
}

extension BaseProtocolForSocket{
    
    public
    func closeSocket() {
        close(socketDescriptor);
    }
    
    /// Returns the (host, service) tuple for a given sockaddr
    func getSockAddrDescription(addr: UnsafePointer<sockaddr>) -> (String?, String?){
        var host : String?
        var service : String?
        
        var hostBuffer = [CChar](repeating: 0, count: Int(NI_MAXHOST))
        var serviceBuffer = [CChar](repeating: 0, count: Int(NI_MAXSERV))
        
        if getnameinfo(
            addr,
            socklen_t(addr.pointee.sa_len),
            &hostBuffer,
            socklen_t(hostBuffer.count),
            &serviceBuffer,
            socklen_t(serviceBuffer.count),
            NI_NUMERICHOST | NI_NUMERICSERV) == 0
        {
            
            host = String(cString: hostBuffer)
            service = String(cString: serviceBuffer)
        }
        
        return (host, service)
    }
    
}
