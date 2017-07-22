//
//  SocketTests.swift
//  SocketKit
//
//  Created by Pawan on 17/06/17.
//  Copyright © 2017 Pawan. All rights reserved.
//

import XCTest
@testable import SocketKitMacOS
import SocketKitMacOS

class ServerTests: XCTestCase {

    var server : Server = Server()

//    override init() {
//        socket = Socket(portNumber: "9999")
//        super.init()
//    }
    
//    override func setUp() {
//        super.setUp()
//        // Put setup code here. This method is called before the invocation of each test method in the class.
//    }
//    
//    override func tearDown() {
//        // Put teardown code here. This method is called after the invocation of each test method in the class.
//        super.tearDown()
//    }

//    func testExample() {
//        // This is an example of a functional test case.
//        // Use XCTAssert and related functions to verify your tests produce the correct results.
//    }
//
//    func testPerformanceExample() {
//        // This is an example of a performance test case.
//        self.measure {
//            // Put the code you want to measure the time of here.
//        }
//    }
    
    func testSocketInitialization(){
        server.setupWith(address: "localhost", andPortNumber: "9999")
        XCTAssertEqual(server.servicePortNumber, "9999")
        XCTAssertNotNil(server.servinfo)
        XCTAssertNotNil(server.servinfo)
        XCTAssertNotEqual(server.socketDescriptor, 0)
        XCTAssertEqual(server.status,0)
    }
    
    func testBindSocketDescriptorToPort(){
        server.setupWith(address: "localhost", andPortNumber: "9999")
        server.Bind()
        XCTAssertEqual(server.status,0)
    }
    
    func testSocketListen(){
        server.setupWith(address: "localhost", andPortNumber: "8888")
        server.Bind()
        server.Listen()
        XCTAssertEqual(server.status,0)
    }
    
    func testWaitForIncomingConnection(){
        server.setupWith(address: "localhost", andPortNumber: "9898")
        server.Bind()
        server.Listen()
        server.Accept()
        XCTAssertNotEqual(server.requestDescriptor,0)
    }

}

class ClientTests: XCTestCase {
    var client : Client = Client()
    
    func testClient(){
        client.setupWith(address: "localhost", andPortNumber: "5555")
        client.Connect()
        client.sartReceiveAndDispatch(socket: client.socketDescriptor)
//        client.Send(payload: client.stringToByteArray(str: "pawan kumar dixitafadf df df ds f adf  ad falllllllllower"), type: 1)
//        client.Send(payload: client.stringToByteArray(str: "sharavan kumar "), type: 2)
//        client.Send(payload: client.stringToByteArray(str: "sharavan dff"), type: 3)
//        client.Send(payload: client.stringToByteArray(str: "sharavan k"), type: 5)
        XCTAssertEqual(client.status,0)
    }
}
