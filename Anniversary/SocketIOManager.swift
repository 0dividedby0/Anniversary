//
//  SocketIOManager.swift
//  Anniversary
//
//  Created by Jason Halcomb on 6/9/19.
//  Copyright © 2019 jhalcomb. All rights reserved.
//

import SocketIO

class SocketIOManager: NSObject {
    static let sharedInstance = SocketIOManager()
    
    let manager = SocketManager(socketURL: URL(string: "http://73.140.192.13:3000")!)
    var socketio: SocketIOClient!
    
    let defaults = UserDefaults.standard
    
    override init() {
        super.init()
        socketio = manager.defaultSocket
    }
    
    func establishConnection() {
        manager.connect()
    }
    
    func closeConnection() {
        manager.disconnect()
    }
    
    func updateDeviceToken(sender: String, token: String) {
        socketio.emit("deviceTokenRegistered", sender, token)
    }
    
    //MARK: - Messages IO
    func sendMessage(sender: String, message: String, date: String) {
        socketio.emit("newMessageFromClient", sender, message, date)
    }
    
    func getMessage(completionHandler: @escaping (_ sender: String, _ message: String) -> Void) {
        socketio!.on("newMessageFromServer", callback: { (data, ack) in
            let sender = data[0] as! String
            let message = data[1] as! String
            completionHandler(sender, message)
        })
    }
    
    func requestAllMessages() {
        socketio.emit("allMessagesRequest")
    }
    
    func receivedAllMessages(completionHandler: @escaping (_ messages: [[String]]?) -> Void) {
        socketio!.on("allMessagesFromServer", callback: { (data, ack) in
            let messages = data[0] as? [[String]]
            completionHandler(messages)
        })
    }
    
    //MARK: - Home IO
    func sendNeedsAttention(sender: String) {
        socketio.emit("clientNeedsAttention", sender)
    }
    
    
    //MARK: - Plans IO
    func sendPlan(sender: String, name: String, location: String, date: String, activities: [String], flights: [String], map: [String], budget: [String], notes: [String]) {
        socketio.emit("newPlanFromClient", sender, name, location, date, activities, flights, map, budget, notes)
    }
    
    func getPlan(completionHandler: @escaping (_ name: String, _ location: String, _ date: String, _ activities: [String], _ flights: [String], _ map: [String], _ budget: [String], _ notes: [String]) -> Void) {
        socketio!.on("newPlanFromServer", callback: { (data, ack) in
            let name = data[0] as! String
            let location = data[1] as! String
            let date = data[2] as! String
            let activities = data[3] as! [String]
            let flights = data[4] as! [String]
            let map = data[5] as! [String]
            let budget = data[6] as! [String]
            let notes = data[7] as! [String]
            completionHandler(name, location, date, activities, flights, map, budget, notes)
        })
    }
    
    func requestAllPlans() {
        socketio.emit("allPlansRequest")
    }
    
    func receivedAllPlans(completionHandler: @escaping (_ plans: [[[String]]]?) -> Void) {
        socketio!.on("allPlansFromServer", callback: { (data, ack) in
            let plans = data[0] as? [[[String]]]
            completionHandler(plans)
        })
    }
    
    //MARK: - Memories IO
    func sendMemory(sender: String, title: String, date: String, description: String) {
        socketio.emit("newMemoryFromClient", sender, title, date, description)
    }
    
    func getMemory(completionHandler: @escaping (_ title: String, _ date: String, _ description: String) -> Void) {
        socketio!.on("newMemoryFromServer", callback: { (data, ack) in
            let title = data[0] as! String
            let date = data[1] as! String
            let description = data[2] as! String
            completionHandler(title, date, description)
        })
    }
    
    func requestAllMemories() {
        socketio.emit("allMemoriesRequest")
    }
    
    func receivedAllMemories(completionHandler: @escaping (_ messages: [[String]]?) -> Void) {
        socketio!.on("allMemoriesFromServer", callback: { (data, ack) in
            let messages = data[0] as? [[String]]
            completionHandler(messages)
        })
    }
}

