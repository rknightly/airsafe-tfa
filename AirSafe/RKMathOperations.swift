//
//  RKMathOperations.swift
//  AirSafe
//
//  Created by Ryan Knightly on 6/14/17.
//  Copyright © 2017 Ryan Knightly. All rights reserved.
//

import Foundation

/// A class to contain extra math operations
class RKMathOperations {
    /// Round a double to one decimal place
    ///
    /// - Parameter num: a double to be rounded
    /// - Returns: the given double rounded to one decimal place
    static func shortened(num: Double) -> Double {
        return round(num * 10) / 10
    }
}
