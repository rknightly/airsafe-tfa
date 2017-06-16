//
//  RKConditions.swift
//  AirSafe TFA
//
//  Created by Ryan Knightly on 6/7/17.
//  Copyright © 2017 Ryan Knightly. All rights reserved.
//

import Foundation
import UIKit

/// A status of the app that can be displayed to the user via the data display, including an image and colored text
struct RKCondition {
    var displayMessage: String = ""
    var imageName: String = ""
    var displayColor: UIColor = .black // the color to make the display message text
    
    init(displayMessage: String, imageName: String, displayColor: UIColor) {
        self.displayMessage = displayMessage
        self.imageName = imageName
        self.displayColor = displayColor
    }
}

/// Each of the possible conditions that can be displayed to the user
class RKConditions {
    /// A condition denoting that the air quality is good and no additional health hazards are presented by the air
    private static var good: RKCondition {
        let color = UIColor(red: 0, green: 153/255, blue: 102/255, alpha: 1)
        return RKCondition(
            displayMessage: "Safe",
            imageName: "goodConditionIcon",
            displayColor: color)
    }
    
    /// A condition denoting that the air quality is not great, but still not at a worrying level of danger
    private static var okay: RKCondition {
        let color = UIColor(red: 231/255, green: 1, blue: 48/255, alpha: 1)
        return RKCondition(displayMessage: "Safe",
                           imageName: "okayConditionIcon",
                           displayColor: color)
    }
    
    
    /// A condition denoting that the concentration of gases in the atmosphere are at serious and dangerous levels, to the point where action should be taken
    private static var dangerous: RKCondition {
        let color = UIColor(red: 224/255, green: 226/255, blue: 3/255, alpha: 1)
        return RKCondition(displayMessage: "Unsafe",
                           imageName: "dangerousConditionIcon",
                           displayColor: color)
    }
    
    /// A condition denoting that the safety risk is unknown due to no nearby sensor
    private static var unknown: RKCondition {
        let color = UIColor(red: 52/255, green: 152/255, blue: 219/255, alpha: 1)
        return RKCondition(displayMessage: "No nearby sensor",
                           imageName: "unknownConditionIcon",
                           displayColor: color)
    }
    
    /// A condition denoting that the user has no connection to the sensor for live data
    private static var noConnection: RKCondition {
        let color = UIColor.black
        return RKCondition(displayMessage: "No connection",
                           imageName: "noConnectionIcon",
                           displayColor: color)
    }
    
    /// A condition denoting that the app is attempting to connect to the sensor
    private static var connecting: RKCondition {
        let color = UIColor.black
        return RKCondition(displayMessage: "Connecting",
                           imageName: "connectingIcon",
                           displayColor: color)
    }
    
    
    /// Determines which of the health warning conditions should be displayed to the user based on the concentration of CH4 in the atmosphere
    ///
    /// - Parameter ppm: the concentration of CH4 in ppm measured to be present in the atmosphere
    /// - Returns: a condition denoting the safety risk resulting from the gas concentration
    public static func getConditionWithReading(ppm: Double) -> RKCondition {
        let condition: RKCondition!
        
        if ppm < 10.0 {
            condition = RKConditions.good 
        } else if ppm < 5000.0 {
            condition = RKConditions.okay
        } else {
            condition = RKConditions.dangerous
        }
        return condition
    }
    
    /// - Returns: The condition that portrays no connection to the mqtt broker
    public static func getNoConnection() -> RKCondition {
        return RKConditions.noConnection
    }
    
    /// - Returns: The condition denoting that the conditions surrounding the user are unknown because of there being no nearby sensor
    public static func getUnknownCondition() -> RKCondition {
        return RKConditions.unknown
    }
    
    /// - Returns: The condition denoting that the app is trying to connect to the mqtt broker
    public static func getConnectingCondition() -> RKCondition {
        return RKConditions.connecting
    }
    
    public static func getDangerousCondition() -> RKCondition {
        return RKConditions.dangerous
    }
    
    /// Return whether a certain sensor reading indicates a dangerous condition
    ///
    /// - Parameter ppm: the recorded concentration of the gas (Methane)
    /// - Returns: boolean denoting whether or not it is dangerous
    public static func isDangerous(ppm: Double) -> Bool {
        let recordedCondition = RKConditions.getConditionWithReading(ppm: ppm).displayMessage
        let dangerousCondition = RKConditions.getDangerousCondition().displayMessage
        
        return recordedCondition == dangerousCondition
    }
}
