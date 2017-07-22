//
//  AppDelegate.swift
//  AppClient
//
//  Created by Pawan on 18/06/17.
//  Copyright © 2017 Pawan. All rights reserved.
/////

import Cocoa
import Foundation

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {



    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        
//        acquirePrivileges()
        
        var monitor = NSEvent.addGlobalMonitorForEvents(
            matching: NSEventMask.rightMouseDown, handler: {(event: NSEvent) in
                print("Pawan: \(event.windowNumber)")
                let appClient = AppClient(type: .Tx, windowId: CGWindowID(event.windowNumber), targetAddress: "localhost", targetPort: "4444")
                //appClient.startAcceptingConnections();
                
                Thread.detachNewThreadSelector(#selector(AppDelegate.mythread), toTarget: self, with: nil)
                
                
                appClient.startCapturing()
                print(event)
                
                NSEvent.removeMonitor(self)
        })
        
        
        
        
    }
    
    func mythread() {
        
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }


}

