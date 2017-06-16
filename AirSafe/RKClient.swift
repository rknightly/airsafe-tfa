//
//  RKClient.swift
//  AirSafe TFA
//
//  Created by Ryan Knightly on 6/5/17.
//  Copyright © 2017 Ryan Knightly. All rights reserved.
//

import Foundation
import MongoKitten
import SwiftChart

/// The MongoDB client that handles all retrieving of data from the MongoDB server
class RKClient {
    private static var server: Server?
    private static var database: Database?
    private static var isSetUp = false
    
    /// Set up the connection to the MongoDB server
    static func setUp() {
        RKClient.connect()
        RKClient.findDatabase()
        isSetUp = true
    }
    
    // return whether the connection was successful
    static func connect() {
        print("Connecting")
        let host = MongoHost(hostname: Secrets.DB_ADDRESS, port: Secrets.DB_PORT)
        let sslSettings = SSLSettings(enabled: false)
        let credentials = MongoCredentials(username: Secrets.DB_USERNAME, password: Secrets.DB_PASSWORD)
        
        let settings = ClientSettings(host: host, sslSettings: sslSettings, credentials: credentials)
        
        do {
            RKClient.server = try Server(settings)
        } catch {
            print(error)
        }
    }
    
    /// initialize the value of database with the proper database from the Mongo server if it is found
    static func findDatabase() {
        if let server = RKClient.server {
            RKClient.database = server["ecox"]
        }
        
    }
    
    /// Set up the connection if it has not been set up previously
    // TODO: - Remove this and handle any arising issues.
    static func setUpIfNecessary() {
        if !RKClient.isSetUp {
            RKClient.setUp()
        }
    }
    
    
    /// Get the documents that describe the sensors from the server
    ///
    /// - Returns: a cursor of the device documents
    static func getDevices() -> Cursor<Document>? {
        setUpIfNecessary()
        var devices: MongoKitten.Collection?
        if let database = RKClient.database {
            devices = database["devices"]
        }
        
        do {
            let query: Query = "type" != "Software"
            let cursor = try devices?.find(query).cursor
            return cursor
        } catch {
            print(error)
            return nil
        }
    }
    
    static func getMQTTDoc() -> Document? {
        var devices: MongoKitten.Collection?
        
        if let database = RKClient.database {
            devices = database["devices"]
        }
        
        do {
            let query: Query = "name" == "MQTT_Broker"
            let mqttDoc = try devices?.findOne(query)
            return mqttDoc
        } catch {
            print(error)
            return nil
        }
        
    }
    
    static func getMQTTServerHost() -> String? {
        if let mqttDoc = RKClient.getMQTTDoc() {
            return String(mqttDoc["ip"])!
        } else {
            return nil
        }
    }
    
    static func getMQTTServerPort() -> UInt16? {
        if let mqttDoc = RKClient.getMQTTDoc() {
            return UInt16(Double(mqttDoc["port"])!)
        } else {
            return nil
        }
    }
    
    /// Get the past observations for the given sensor
    ///
    /// - Parameters:
    ///   - named: The string of the sensor name as it appears in the Mongo Databas
    ///   - days: The number of days back to get observations for
    /// - Returns: an array of the observation documents
    static func getObservationsForSensor(named: String, back days: Double) -> [Document] {
        var observations: MongoKitten.Collection?
        if let database = RKClient.database {
            observations = database["observations"]
        }
        let measurementsPerSecond = 1.0
        // The number of measurements that were recorded during that time
        let measurementCount: Int = Int(days * 24 * 60 * 60 * measurementsPerSecond)
        // The number of measurements that the client should request
        let measurementsToRequest: Int = Int(days * 24)  // Get one measurement per hour
        // The number of measurements that should be skipped between requested measurements
        let measurementsToSkip = measurementCount / measurementsToRequest
        
        var observationDocs = [Document]()
        for measurementNum in stride(from: measurementsToRequest, through: 0, by: -1) {
            do {
                print("Measurement: ", measurementNum)
                let query: Query = "deviceName" == named
                let sortDocument: Sort = Sort(["obs_Time": -1])
                let currentSkipAmount = measurementNum * measurementsToSkip
                let observationDoc = try observations?.findOne(query, sortedBy: sortDocument, skipping: currentSkipAmount)
                observationDocs.append(observationDoc!) // TODO: remove force
            } catch {
                print(error)
            }
        }
        return observationDocs
    }
    
    /// Disconnect from the server if posssible
    static func disconnect() {
        if let server = RKClient.server {
            do {
                try server.disconnect()
            } catch {
                print(error)
            }
        }
    }
    
}
