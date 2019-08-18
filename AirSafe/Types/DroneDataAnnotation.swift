//
//  DroneDataAnnotation.swift
//  AirSafe
//
//  Created by Ryan Knightly on 8/9/19.
//  Copyright © 2019 Ryan Knightly. All rights reserved.
//

import Foundation
import MapKit

class DroneDataAnnotation: NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D
    var title: String?
    var image: UIImage?
    
    var droneData: DroneData!
    
    init(droneData: DroneData) {
        self.coordinate = droneData.location
        self.title = droneData.name
        self.droneData = droneData
    }
    
    func getColorName(thresholds: Thresholds?) -> String{
        if thresholds != nil {
            return thresholds!.getStatus(concentration: droneData.concentration).colorName
        } else {
            return "white"
        }
    }
    
    func getColor(thresholds: Thresholds?) -> UIColor{
        return UIColor(name: getColorName(thresholds: thresholds))!
    }
}
