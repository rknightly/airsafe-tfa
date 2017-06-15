//
//  DateExtension.swift
//  AirSafe TFA
//
//  Created by Ryan Knightly on 6/9/17.
//  Copyright © 2017 Ryan Knightly. All rights reserved.
//

import Foundation

extension NSDate {
    /// Find the day of the week of the date denoted by the NSDate object
    ///
    /// - Returns: the day of the week
    func dayOfTheWeek() -> String? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE"
        return dateFormatter.string(from: self as Date)
    }
}
