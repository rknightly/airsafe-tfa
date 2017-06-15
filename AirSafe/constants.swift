//
//  constants.swift
//  AirSafe TFA
//
//  Created by Ryan Knightly on 6/8/17.
//  Copyright © 2017 Ryan Knightly. All rights reserved.
//

import Foundation

// The maximum distance (in miles) that the user can be located away 
// from a sensor for the sensor readings to be considered meaingful to the user.
let MAX_SENSOR_DIST: Double = 5
// Ex: with a MAX_SENSOR_DIST of 5, if there is no sensor within a 5 mile radius of the user,
// they will not have a condition displayed and will not be given push notifications

