//
//  RKSensor.swift
//  AirSafe
//
//  Created by Ryan Knightly on 8/7/19.
//  Copyright © 2019 Ryan Knightly. All rights reserved.
//

import Foundation
import CoreLocation
import MapKit
import SwiftyJSON

class Sensor {
    var location: CLLocationCoordinate2D
    var name: String
    var concentration: Double

    init(name: String, lat: Double, lon: Double, concentration: Double) {
        self.name = name
        self.location = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        self.concentration = concentration
    }
    
    convenience init(json: JSON) {
        self.init(
            name: json["name"].stringValue,
            lat: json["lat"].doubleValue,
            lon: json["lon"].doubleValue,
            concentration: json["concentration"].doubleValue
        )
    }
    
    func makeMapAnnotation() -> MKAnnotation {
        return SensorReadingAnnotation(sensorReading: self)
    }
}
