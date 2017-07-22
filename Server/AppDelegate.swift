//
//  AppDelegate.swift
//  Server
//
//  Created by Pawan on 17/06/17.
//  Copyright © 2017 Pawan. All rights reserved.
//

import Cocoa
import SocketKitMacOS

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {


    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        
        let server = Server();
//        var client = Client();
        
        server.setupWith(address: "localhost", andPortNumber: "8888")
        server.Bind()
        server.Listen()
        server.Accept(CompletionHandler: { clientDescripter in
            print("Server : \(clientDescripter)")
            
        })
        
        server.Send(requestDescriptor: server.requestDescriptor, payload: [UInt8]("pawan".utf8), type: 4)
        sleep(10)
        server.Send(requestDescriptor: server.requestDescriptor, payload: [UInt8]("Dixit".utf8), type: 4)
        
//        client.setupWith(address: "localhost", andPortNumber: "7777")
//        client.Connect();
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }


}

