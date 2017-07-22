//
//  AppClient.swift
//  SocketKit
//
//  Created by Pawan on 18/06/17.
//  Copyright © 2017 Pawan. All rights reserved.
////

import Foundation
import SocketKitMacOS

enum AppClientType{
    case Tx, Rx
}

class AppClient {
    
    var Ptype : AppClientType
    
    var server = Server();
    var client = Client();
    
    var PwindowId : CGWindowID
    
    var PtargetAddress : String
    var PtargetPort : String
    
    var PframeQueue = DispatchQueue(
        label: "FrameQueue",
        qos: .utility
    )
    
    var PPacketQueue = DispatchQueue(
        label: "PacketQueue",
        qos: .utility
    )
    
    init(type : AppClientType, windowId : CGWindowID, targetAddress : String, targetPort : String ) {
        Ptype = type
        PwindowId = windowId
        PtargetAddress = targetAddress
        PtargetPort = targetPort
        
        if(Ptype == .Rx)
        {
            client.setupWith(address: "localhost", andPortNumber: "4444")
            client.Connect()
        }
        else
        {
            server.setupWith(address: "localhost", andPortNumber: "4444")
            server.bindSocketDescriptorToPort()
            server.startListening()
        }
        
    }
    
    func startAcceptingConnections(){
        server.startAcceptingConnections()
    }
    
    
    func startCapturing(){
        while(true)
        {
            let frame : CGImage = CGWindowListCreateImage(CGRect.null, CGWindowListOption.optionIncludingWindow, PwindowId, CGWindowImageOption.boundsIgnoreFraming)!;
            
            //var image : NSImage = NSImage.init(cgImage: frame, size: NSZeroSize)
            
            
            //let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil)!
            let bitmapRep = NSBitmapImageRep(cgImage: frame)
            let jpegData = bitmapRep.representation(using: NSBitmapImageFileType.JPEG, properties: [:])!
            
            let dataBytes = Array(jpegData)
        
            
            //let data = image.tiffRepresentation!
            
            
            
            PframeQueue.async() { self.createAndSendPacket(payload : dataBytes, Withtype : 5)}
        }
    }
    
    func createAndSendPacket(payload : [UInt8], Withtype : UInt32){
        //let payload = [UInt8]("pawan".utf8)
        print("Sending : \(payload.count) bytes")
        server.Send(requestDescriptor: server.requestDescriptor, payload: payload, type: Withtype)
        
//        let packetSize : UInt32 = UInt32(payload.count)
//        let type : UInt32 = 5
//        let packetSizeByteArray = server.toByteArray(packetSize)
//        let typeByteArray = server.toByteArray(type)
//        
//        let headerBytes = packetSizeByteArray + typeByteArray
//        
//        let buffer =  headerBytes + payload
//        
//        //        let packetSizeBack : UInt32?
//        //        let typeBack : UInt32?
//        //
//        //        (packetSizeBack, typeBack) = decodeHeader(headerBytes: buffer)
        

        //PPacketQueue.async() { self.sendPacket(packet : buffer, type : type)}
    }
    
    func sendPacket(packet : [UInt8], type : UInt32){
        
        client.Send(payload : packet, type : type)
        
        // Cop out if there are any errors
        if server.status != 0
        {
            let strError = String(utf8String: strerror(errno)) ?? "Unknown error code"
            let message = "Listen error \(errno) (\(strError))"
            print(message)
            close(server.socketDescriptor)         // Ignore possible errors
            return
        }
    }
}
