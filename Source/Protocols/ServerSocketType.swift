//
//  ServerSocket.swift
//  SocketKit
//
//  Created by Pawan on 17/06/17.
//  Copyright © 2017 Pawan. All rights reserved.
//

import Foundation

public
protocol ServerSocketType: BaseProtocolForSocket, AcceptedClientSocketType {
    var requestDescriptor : Int32 { get set }
    var maxNumberOfConnectionsBeforeAccept: Int32 { get set}
    
    var connectionQueue : DispatchQueue { get set }
    
    //func sartReceiveAndDispatch(socket: Int32)
    
    func Bind()
    func Listen()
    func Accept(CompletionHandler : @escaping (Int32) -> Swift.Void)
    
}

extension ServerSocketType{
}
