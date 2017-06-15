//
//  RKSensor.swift
//  AirSafe TFA
//
//  Created by Ryan Knightly on 6/8/17.
//  Copyright © 2017 Ryan Knightly. All rights reserved.
//

import Foundation
import CoreLocation

/// A struct describing a sensor that gives live data to an mqtt broker
struct RKSensor {
    var name: String!
    var mqttTopic: String!
    var description: String!
    var location: CLLocationCoordinate2D!
    var isGasSensor: Bool!
    
    init(name: String, mqttTopic: String, description: String, location: CLLocationCoordinate2D) {
        self.name = name
        self.mqttTopic = mqttTopic
        self.description = description
        self.location = location
        
        // Assume that all wind sensors will contain "wind"
        self.isGasSensor = !self.name.lowercased().contains("wind")
    }
}
