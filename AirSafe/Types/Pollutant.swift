//
//  Pollutant.swift
//  AirSafe
//
//  Created by Ryan Knightly on 8/7/19.
//  Copyright © 2019 Ryan Knightly. All rights reserved.
//

import Foundation
import SwiftyJSON

class Pollutant {
    var name: String
    var abbreviation: String
    var timeResolutions: [String]

    static let timeResolutionAbbreviations = [
        "1 Minute": "1min",
        "10 Minutes": "10min",
        "1 Hour": "1hr",
        "8 Hours": "8hr",
        "24 Hours": "24hr",
        "drone": "drone"
    ]
    
    init(name: String, abbreviation: String, timeResolutions: [String]) {
        self.name = name
        self.abbreviation = abbreviation
        self.timeResolutions = timeResolutions
    }

    convenience init(name: String, json: JSON) {
        var resolutions = [String]()
        for resolution in json["resolutions"].arrayValue {
            resolutions.append(resolution.stringValue)
        }
        self.init(
            name: name,
            abbreviation: json["abbr"].stringValue,
            timeResolutions: resolutions
        )
    }
    
    func getTimeResolutionNames() -> [String] {
        var result = [String]()
        for abbreviation in timeResolutions {
            for fullName in Pollutant.timeResolutionAbbreviations.keys {
                if Pollutant.timeResolutionAbbreviations[fullName] == abbreviation {
                    result.append(fullName)
                }
            }
        }
        return result
    }
}
