//
//  SensorReading.swift
//  AirSafe
//
//  Created by Ryan Knightly on 8/9/19.
//  Copyright © 2019 Ryan Knightly. All rights reserved.
//

import Foundation
import CoreLocation
import MapKit
import SwiftyJSON

class SensorReading {
    var location: CLLocationCoordinate2D
    var sensorName: String
    var concentration: Double
    var timeStamp: Double?
    
    init(name: String, lat: Double, lon: Double, concentration: Double, timeStamp: Double?) {
        self.sensorName = name
        self.location = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        self.concentration = concentration
        self.timeStamp = timeStamp
    }
    
    convenience init(json: JSON, name: String, timeStamp: Double?) {
        self.init(
            name: name,
            lat: json["lat"].doubleValue,
            lon: json["lon"].doubleValue,
            concentration: json["concentration"].doubleValue,
            timeStamp: timeStamp
        )
    }
    
    func getDateString() -> String {
        let date = Date(timeIntervalSince1970: timeStamp!)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm MMM dd" //Specify your format that you want
        return dateFormatter.string(from: date)
    }
}
