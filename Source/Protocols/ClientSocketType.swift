//
//  ClientSocketType.swift
//  SocketKit
//
//  Created by Pawan on 17/06/17.
//  Copyright © 2017 Pawan. All rights reserved.
//

import Foundation

public
protocol ClientSocketType : BaseProtocolForSocket {
    
    func Connect()
    func sartReceiveWith(completionHandler : (Data, UInt32) -> Swift.Void)
    
}

extension ClientSocketType{
}
