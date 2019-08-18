//
//  Config.swift
//  AirSafe
//
//  Created by Ryan Knightly on 8/15/19.
//  Copyright © 2019 Ryan Knightly. All rights reserved.
//

import Foundation

struct Config {
    static let POLLUTANTS_WEB_SERVICE = "http://astro-web-server.us-west-2.elasticbeanstalk.com/get_pollutants.php"
    static let THRESHOLDS_WEB_SERVICE = "http://astro-web-server.us-west-2.elasticbeanstalk.com/get_thresholds.php"
    static let SENSORS_WEB_SERVICE = "http://astro-web-server.us-west-2.elasticbeanstalk.com/get_sensors.php"
    static let DRONE_DATA_WEB_SERVICE = "http://astro-web-server.us-west-2.elasticbeanstalk.com/get_drone_data.php"
    static let HISTORICAL_DATA_WEB_SERVICE = "http://astro-web-server.us-west-2.elasticbeanstalk.com/get_historical_data.php"
    static let INFO_URL_WEB_SERVICE = "http://astro-web-server.us-west-2.elasticbeanstalk.com/get_info.php"
}
