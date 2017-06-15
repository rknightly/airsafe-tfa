//
//  RKMQTTConnection.swift
//  AirSafe
//
//  Created by Ryan Knightly on 6/14/17.
//  Copyright © 2017 Ryan Knightly. All rights reserved.
//

import Foundation
import CocoaMQTT

/// A class to handle the mqtt connections, created so that the connection can be passed between the background and foreground
class RKMQTTConnectionManager {
    private static var mqttConnection: CocoaMQTT?
    private static var currentSensorTopic: String!
    public static var isSetup = false
    
    /// Setup an initial mqtt connection
    public static func setup() {
        // Use a default IP for initial connection so that the live data can appear while waiting for the MongoDB data
        currentSensorTopic = "Sensor1/ppmv"
        connectWith(host: Secrets.MQTT_ADDRESS, port: Secrets.MQTT_PORT)
        isSetup = true
    }
    
    /// Create a connection to the specified mqtt  broker
    ///
    /// - Parameters:
    ///   - host: a string of the broker's address
    ///   - port: a uint16 of the broker's port number
    public static func connectWith(host: String, port: UInt16) {
        let clientID = "CocoaMQTT-" + String(ProcessInfo().processIdentifier)
        
        mqttConnection = CocoaMQTT(clientID: clientID, host: host, port: port)
        mqttConnection!.username = Secrets.MQTT_USERNAME
        mqttConnection!.password = Secrets.MQTT_PASSWORD
        mqttConnection!.willMessage = CocoaMQTTWill(topic: "/will", message: "dieout")
        mqttConnection!.keepAlive = 60
        mqttConnection!.autoReconnect = true
        mqttConnection!.autoReconnectTimeInterval = 1
        mqttConnection!.connect()
    }
    
    
    /// Set the delegate for the mqtt connection to receive the new messages from the broker
    ///
    /// - Parameter delegate: the new delegate to receive the messages
    public static func setDelegate(delegate: CocoaMQTTDelegate) {
        RKMQTTConnectionManager.mqttConnection?.delegate = delegate
    }
    
    /// Subscribe to the given topic after unsubscribing to the previously subscribed topic if necessary
    ///
    /// - Parameter topic: the new topic name to subscribe to
    public static func subscribe(to topic: String) {
        if let previousTopic = currentSensorTopic {
            mqttConnection?.unsubscribe(previousTopic)
        }
        mqttConnection?.subscribe(topic)
        currentSensorTopic = topic
    }
    
    /// Establish a basic connnection if none has been created yet
    public static func createConnectionIfNecessary() {
        if mqttConnection == nil {
            connectWith(host: Secrets.MQTT_ADDRESS, port: Secrets.MQTT_PORT)
        }
    }
}
