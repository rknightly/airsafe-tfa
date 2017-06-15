//
//  RKSensorAnnotation.swift
//  AirSafe TFA
//
//  Created by Ryan Knightly on 6/6/17.
//  Copyright © 2017 Ryan Knightly. All rights reserved.
//

import Foundation
import MapKit

/// A map annotation that describes one of the sensors
class RKSensorAnnotation: NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D
    var title: String?
    var image: UIImage?
    
    var identifier = "sensor"
    var color: UIColor!
    var sensor: RKSensor!
    
    
    init(sensor: RKSensor) {
        self.coordinate = sensor.location
        title = "Methane Concentration (ppm)"
        //TODO: add colors to each pin with below code after a reading for each sensor is obtained
//        color = RKConditions.getConditionWithReading(ppm: gasReading).displayColor
        self.sensor = sensor
    }
    
}
