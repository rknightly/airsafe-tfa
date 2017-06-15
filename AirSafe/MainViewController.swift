//
//  DataViewController.swift
//  AirSafe TFA
//
//  Created by Ryan Knightly on 5/27/17.
//  Copyright © 2017 Ryan Knightly. All rights reserved.
//

import UIKit
import CocoaMQTT
import MongoKitten
import SwiftChart
import CoreLocation
import MapKit

/// The view controller that handles the main view
class MainViewController: UIViewController {
    
    @IBOutlet var sensorDescriptionLabel: UILabel!
    @IBOutlet var ppmLabel: UILabel!
    @IBOutlet var statusLabel: UILabel!
    @IBOutlet var sensorDistanceLabel: UILabel!
    @IBOutlet var statusImageView: UIImageView!
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    
    var mqttDataReceived = false
    
    var nearestSensorDistance: Double!
    var userHasConnection: Bool!
    var currentCondition: RKCondition?
    var currentSensorTopic: String?
    
    let manager = CLLocationManager()
    var hasCenteredOnUser = false
    var userLocation: CLLocation!
    @IBOutlet var map: MKMapView!
    
    /// Initialize the view
    override func viewDidLoad() {
        super.viewDidLoad()
        startActivityIndicator()
        setupMQTT()
        loadMap()
        addNotificationListeners()
    }
    
    /// Called after the view appears
    override func viewDidAppear(_ animated: Bool) {
        // Load the sensors after the view appears so that the view is visible while the data is loading
        self.loadSensorLocations()
    }
    
    /// Initially setup the mqtt connection
    func setupMQTT() {
        RKMQTTConnectionManager.setup()
        makeMQTTDelegate()
        currentSensorTopic = "Sensor1/ppmv"
        showCondition(condition: RKConditions.getConnectingCondition())
    }
    
    /// Make this view controller the mqtt delegate so that it will receive the messages from the broker
    func makeMQTTDelegate() {
        RKMQTTConnectionManager.setDelegate(delegate: self)
    }
    
    /// Add the notification listeners
    func addNotificationListeners() {
        NotificationCenter.default.addObserver(self, selector: #selector(MainViewController.makeMQTTDelegate),
                                               name: NSNotification.Name(rawValue: "returnMQTTDelegateResponsibility"),
                                               object: nil)
    }
    
    //# MARK: - Activity Indicator
    
    /// Start spinning the activity indicator
    func startActivityIndicator() {
        activityIndicator.hidesWhenStopped = true
        activityIndicator.startAnimating()
    }
    
    /// Stop spinning the activity indicator
    func stopActivityIndicator() {
        activityIndicator.stopAnimating()
    }
    
    //# MARK: - NearestSensor
    func showNearestSensorIs(away distance: Double) {
        let roundedDistance: Double = round(distance * 100) / 100
        sensorDistanceLabel.text = String(roundedDistance) + " miles away"
        
        if currentCondition?.displayMessage == RKConditions.getUnknownCondition().displayMessage {
            // Only show as loading if there previously was no nearby sensor
            // TODO: Remove after ip retrieved from database
            showCondition(condition: RKConditions.getConnectingCondition())
        }
    }
    
    /// Take a string from the mqtt and update the data displays accordingly if possible
    ///
    /// - Parameter msg: the string of the received reading from the mqtt broker
    func handleMessage(msg: String) {
        print(msg)
        if let msgDouble = Double(msg) {
            updateWithSensorReading(ppm: msgDouble)
        }
    }
    
    // MARK: - Data display
    /// Set the ppm label to show the given value
    ///
    /// - Parameter ppm: the current value of the sensor in ppm
    func setLabelWith(ppm: Double) {
        ppmLabel.text = String(RKMathOperations.shortened(num: ppm)) + " ppm"
    }
    
    /// Update the data displays to reflect the given sensor reading
    ///
    /// - Parameter ppm: the sensor reading as a double
    func updateWithSensorReading(ppm: Double) {
        setLabelWith(ppm: ppm)
        let condition = RKConditions.getConditionWithReading(ppm: ppm)
        showCondition(condition: condition)
    }
    
    /// Determine whether the user is close enough to a sensor to be reasonably
    /// concerned with its readings
    /// - Returns: a boolean denoting if a sensor is nearby the current user location
    func isASensorNearby() -> Bool {
        if let condition = currentCondition {
            return condition.displayMessage != RKConditions.getUnknownCondition().displayMessage
        } else {
            return false
        }
    }
    
    /// Update the status label and image to reflect the current condition
    ///
    /// - Parameter condition: the condition to display to the user
    func showCondition(condition: RKCondition) {
        currentCondition = condition
        
        statusImageView.image = UIImage(named: condition.imageName)
        statusLabel.text = condition.displayMessage
        statusLabel.textColor = condition.displayColor
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

// MARK: - CocoaMQTTDelegate
extension MainViewController: CocoaMQTTDelegate {
    func mqtt(_ mqtt: CocoaMQTT, didConnect host: String, port: Int) {
        print("didConnect \(host):\(port)")
        if let topic = currentSensorTopic {
            mqtt.subscribe(topic)
        }
        
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didReceiveMessage message: CocoaMQTTMessage, id: UInt16 ) {
        if (!mqttDataReceived) {
            mqttDataReceived = true
            stopActivityIndicator()
        }
        handleMessage(msg: message.string!)
    }
    
    // Optional ssl CocoaMQTTDelegate
    func mqtt(_ mqtt: CocoaMQTT, didReceive trust: SecTrust, completionHandler: @escaping (Bool) -> Void) {
        completionHandler(true)
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didConnectAck ack: CocoaMQTTConnAck) {
        print("didConnectAck: \(ack)，rawValue: \(ack.rawValue)")
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didPublishMessage message: CocoaMQTTMessage, id: UInt16) {
        print("didPublishMessage with message: \(String(describing: message.string))")
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didPublishAck id: UInt16) {
        print("didPublishAck with id: \(id)")
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didSubscribeTopic topic: String) {
        print("didSubscribeTopic to \(topic)")
        currentSensorTopic = topic
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didUnsubscribeTopic topic: String) {
        print("didUnsubscribeTopic to \(topic)")
    }
    
    func mqttDidPing(_ mqtt: CocoaMQTT) {
        print("didPing")
    }
    
    func mqttDidReceivePong(_ mqtt: CocoaMQTT) {
        _console("didReceivePong")
    }
    
    func mqttDidDisconnect(_ mqtt: CocoaMQTT, withError err: Error?) {
        _console("mqttDidDisconnect")
    }
    
    func _console(_ info: String) {
        print("Delegate: \(info)")
    }
}

// MARK: - MKMapViewDelegate, CLLocationManagerDelegate
extension MainViewController: MKMapViewDelegate, CLLocationManagerDelegate {
    /// Initialize the map view
    func loadMap() {
        map.delegate = self
        setUpMap()
    }
    
    /// Start requesting user location and set map settings
    func setUpMap() {
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
        
        
        // Initially set the location of the map to be at the original sensor location
        let location = CLLocationCoordinate2DMake(29.707060, -95.278968)
        
        centerMap(newCoord: location)
        
        self.map.showsUserLocation = true
        self.map.isRotateEnabled = false
    }
    
    /// Center the map view on the given point
    ///
    /// - Parameter newCoord: the new coordinate to place at the center of the map
    func centerMap(newCoord: CLLocationCoordinate2D) {
        let span = MKCoordinateSpanMake(0.35, 0.35)
        let region = MKCoordinateRegionMake(newCoord, span)
        map.setRegion(region, animated: true)
    }
    
    /// Called when the user location changes
    func locationManager(_ manager: CLLocationManager,
    didUpdateLocations locations: [CLLocation]){
        // Take only the most recent location
        userLocation = locations[0]
        
        // Update the nearest sensor distance
        if let closestSensor = self.findClosestSensor() {
            self.showNearestSensorIs(away: milesFrom(sensor: closestSensor))
            self.sensorDescriptionLabel.text = closestSensor.description
            if !RKMQTTConnectionManager.isSetup {
            } else if currentSensorTopic == nil || closestSensor.mqttTopic != currentSensorTopic {
                RKMQTTConnectionManager.subscribe(to: closestSensor.mqttTopic)
            }
        }
        if let closestDistance = self.calculateClosestSensorDistance() {
            self.showNearestSensorIs(away: closestDistance)
        }
        
        // Center the map on the user, but only when the app first loads so that the user can scroll the map without it recentering on their location
        if (!hasCenteredOnUser) {
            centerMap(newCoord: userLocation.coordinate)
            self.map.showsUserLocation = true
            
            hasCenteredOnUser = true
        }
    }
    
    /// Create and add a sensor annotation for the given sensor
    ///
    /// - Parameter sensor: the sensor to create an annotation for
    func addSensorAnnotation(for sensor: RKSensor) {
        let annotation = RKSensorAnnotation(sensor: sensor)
        
        // Need to add annotations in main thread
        self.map.addAnnotation(annotation)
    }
    
    /// Get sensor locations from the MongoDB server and create a sensor annotation with each location
    func loadSensorLocations() {
        if let devicesDocs = RKClient.getDevices() {
            for device in devicesDocs {
                let location = device["location"]
                
                // GeoJSON formats with (long, lat) rather than (lat, long) so pull coords in reverse order
                let coordinates = CLLocationCoordinate2DMake(
                    CLLocationDegrees(location["coordinates"][1])!,
                    CLLocationDegrees(location["coordinates"][0])!)
                if !String(device["name"])!.contains("Wind") { // Ignore the wind sensors
                    let sensor = RKSensor(name: String(device["name"])!,
                                          mqttTopic: String(device["mqtt_topic"])!,
                                          description: String(device["description"])!,
                                          location: coordinates)
                    addSensorAnnotation(for: sensor)
                }
            }
        }
    }
    
    //# MARK: - Closest sensor
    
    /// Finds the sensor closest to the user
    ///
    /// - Returns: the sensor who's location is closest to the user's current location
    func findClosestSensor() -> RKSensor? {
        var shortestDistance: Double?
        var closestSensor: RKSensor?
        for annotation in map.annotations {
            if let sensorAnnotation = annotation as? RKSensorAnnotation {
                
                let distance = metersFromSensor(sensor: sensorAnnotation.sensor)
                
                if shortestDistance == nil || distance < shortestDistance! {
                    shortestDistance = distance
                    closestSensor = sensorAnnotation.sensor
                }
            }
        }
        return closestSensor
    }
    
    /// Get the distance from the user to the closest sensor
    ///
    /// - Returns: The distance from the user to the closest sensor in miles
    func calculateClosestSensorDistance() -> Double? {
        var distance: Double?
        if let closestSensor = findClosestSensor() {
            distance = milesFrom(sensor: closestSensor)
        }
        return distance
    }
    
    /// Convert meters to miles
    ///
    /// - Parameter meters: A measurement in meters
    /// - Returns: The same measurement in miles
    func metersToMiles(meters: Double) -> Double {
        return meters / 1609.344
    }
    
    /// Calculate the meters between the user and a given sensor
    ///
    /// - Parameter sensor: the sensor to calculate the distance from
    /// - Returns: The distance between the user and the sensor in meters
    func metersFromSensor(sensor: RKSensor) -> Double {
        let sensorLocation = CLLocation(
            latitude: sensor.location.latitude,
            longitude: sensor.location.longitude)
        let distance = sensorLocation.distance(from: userLocation)
        return distance

    }
    
    /// Find the distance from a sensor in miles
    ///
    /// - Parameter sensor: the sensor to calculate the distance from
    /// - Returns: The distance between the user and the sensor in miles
    func milesFrom(sensor: RKSensor) -> Double {
        return metersToMiles(meters: metersFromSensor(sensor: sensor))
    }
    
    /// Create a view for any annotation that is created
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        var view : MKPinAnnotationView
        guard let annotation = annotation as? RKSensorAnnotation else {return nil}
        if let dequeuedView = mapView.dequeueReusableAnnotationView(withIdentifier: annotation.identifier){
            view = dequeuedView as! MKPinAnnotationView
        } else {
            //make a new view
            view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: annotation.identifier)
            view.pinTintColor = annotation.color
            view.canShowCallout = true
        }
        return view
    }
    
    /// Convert a date string to an NSDate object
    ///
    /// - Parameter date: a string of the date in the MongoDB format
    /// - Returns: an NSDate object that describes the date denoted by the string
    func stringToDate(date:String) -> NSDate? {
        let formatter = DateFormatter()
        let splitedDate = date.components(separatedBy: " ")
        if splitedDate.count > 0 {
            formatter.dateFormat = "yyyy-MM-dd HH:mm:SS"
            if let date: Date = formatter.date(from: splitedDate[0] + " " + splitedDate[1]) {
                
                let source_timezone = TimeZone(abbreviation: "GMT")
                let local_timezone = NSTimeZone.system
                let source_EDT_offset = source_timezone?.secondsFromGMT(for: date)
                let destination_EDT_offset = local_timezone.secondsFromGMT(for: date)
                let time_interval : TimeInterval = Double(destination_EDT_offset - source_EDT_offset!)
                
                
                let final_date = NSDate(timeInterval: time_interval, since: date)
                
                return final_date
            }
        }
        return nil
    }
    
    /// Return an abbreviation of the weekday of the given date
    ///
    /// - Parameter date: the date to find the day of the week for
    /// - Returns: a 3 character string describing the day of the week of the input date
    func dayOfWeek(at date: NSDate) -> String {
        let dayName = date.dayOfTheWeek()
        let abbrevIndex = dayName!.index(dayName!.startIndex, offsetBy: 3)
        return dayName!.substring(to: abbrevIndex)
    }
    
    /// Create a chart to display the recorded data of a given sensor
    ///
    /// - Parameters:
    ///   - named: the name of the sensor
    ///   - days: the number of days worth of data to display in the chart
    /// - Returns: a formatted line chart displaying the past observations of the specified sensor
    func getChartForSensor(named: String, back days: Double) -> Chart {
        let chart = Chart(frame: CGRect(x: 0, y: 0, width: 50, height: 25))
        // Set a range of 0 to 4 because the reading usually hovers between 2 and 3
        chart.minY = 0
        chart.maxY = 4
        
        var data: [(x: Float, y: Float)] = []
        let observationDocs = RKClient.getObservationsForSensor(named: named, back: days)
        
        var labels: [Float] = []  // The x values where labels should be placed
        var labelsAsString: Array<String> = [] // The labels as strings that will go on the x axis as labels
        
        for observationDoc in observationDocs {
            let sensorReading: Float = Float(Double(observationDoc["obs_Value"])!)
            
            let timeString: String = String(describing: observationDoc["obs_Time"]!)
            print("time string:", timeString)
            
            if let date = stringToDate(date: timeString) {
                print(date.timeIntervalSince1970)
                data.append((x: Float(date.timeIntervalSince1970), y: sensorReading))
                print(date.dayOfTheWeek()!)
                
//                let dateFormatter.timeZone = NSTimeZone(abbreviation: "CST") //dateFormatter.timeZone = NSTimeZone(abbreviation: "GMT")
//                let localDate = dateFormatter.dateFromString(string: date as String)
                let hour: String = String(Calendar.current.component(.hour, from: date as Date))
                if labels.count == 0 || labelsAsString.last != hour {
                    labels.append(Float(date.timeIntervalSince1970))
                    
                    labelsAsString.append(hour + ":00")
                }
            }
        }
        let series = ChartSeries(data: data)
        chart.xLabels = labels
        chart.xLabelsFormatter = {(labelIndex: Int, labelValue: Float) -> String in
            return labelsAsString[labelIndex]
        }
        chart.xLabelsTextAlignment = .center
        chart.yLabels = [0, 1, 2, 3, 4]
        series.area = true
        chart.add(series)
        
        return chart
    }
    
    /// Create a graph to display when one of the sensor annotations is selected
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView){
        print("Pin clicked")
        if let annotation = view.annotation as? RKSensorAnnotation {
            RKMQTTConnectionManager.subscribe(to: annotation.sensor.mqttTopic) // TODO: unsubscribe first
            
            let popUpView = getChartForSensor(named: annotation.sensor.name, back: 0.25)
            
            //TODO: get ip of mqqt and connect
            
            let widthConstraint = NSLayoutConstraint(item: popUpView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 325)
            popUpView.addConstraint(widthConstraint)
            
            let heightConstraint = NSLayoutConstraint(item: popUpView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 130)
            popUpView.addConstraint(heightConstraint)
            view.detailCalloutAccessoryView = popUpView
        }
    }
}
