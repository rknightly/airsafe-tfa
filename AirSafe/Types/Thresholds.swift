//
//  Thresholds.swift
//  AirSafe
//
//  Created by Ryan Knightly on 8/8/19.
//  Copyright © 2019 Ryan Knightly. All rights reserved.
//

import Foundation
import SwiftyJSON

class Thresholds {
    var thresholdNames = [String]()
    var thresholdValues = [Double]()
    var colorNames = [String]()
    
    init(thresholdNames: [String], thresholdValues: [Double], colorNames: [String]) {
        self.thresholdNames = thresholdNames
        self.thresholdValues = thresholdValues
        self.colorNames = colorNames
    }
    
    convenience init(json: JSON) {
        self.init(
            thresholdNames: json["thresholds"].arrayObject as! [String],
            thresholdValues: json["threshold_values"].arrayObject as! [Double],
            colorNames: json["colors"].arrayObject as! [String]
        )
    }

    func getStatus(concentration: Double) -> (name: String, colorName: String) {
        var i = 0;
        while (i<thresholdValues.count && concentration>thresholdValues[i]) {
            i += 1
        }
        return (name: thresholdNames[i], colorName: colorNames[i])
    }
    
    func getRangeString(concentration: Double) -> String {
        var i = 0;
        while (i<thresholdValues.count && concentration>thresholdValues[i]) {
            i += 1
        }
        if i == 0 {
            return String(format: "0-%.1f", thresholdValues[i])
        }
        if i == thresholdValues.count - 1 {
            return String(format: "%.1f+", thresholdValues[i])
        }
        return String(format: "%.1f-%.1f", thresholdValues[i-1], thresholdValues[i])
    }
}
