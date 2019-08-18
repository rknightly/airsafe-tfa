//
//  File.swift
//  AirSafe
//
//  Created by Ryan Knightly on 8/6/19.
//  Copyright © 2019 Ryan Knightly. All rights reserved.
//

import Foundation
import CoreLocation
import MapKit
import iOSDropDown
import SwiftyJSON

class MainViewController: UIViewController {
    @IBOutlet weak var pollutantSelector: DropDown!
    @IBOutlet weak var timeResolutionSelector: DropDown!
    @IBOutlet weak var droneDataSelector: DropDown!
    
    @IBOutlet weak var pollutantLabel: UILabel!
    @IBOutlet weak var pollutionLevelLabel: UILabel!
    @IBOutlet weak var safetyLevelLabel: UILabel!
    @IBOutlet weak var thresholdLabel: UILabel!
    @IBOutlet weak var sensorDistanceLabel: UILabel!
    
    @IBOutlet weak var map: MKMapView!
    let manager = CLLocationManager()
    var hasCenteredOnUser = false
    var userLocation: CLLocation?
    var pollutants = [String: Pollutant]()
    
    var pollutant: Pollutant!
    var timeResolution: String!
    var shouldShowDroneData: Bool! = false
    
    var stationarySensorReadings = [SensorReading]()
    var droneSensorReadings = [SensorReading]()
    var thresholds: Thresholds?

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpDropDowns()
        loadPollutants()
        setUpMap()
    }
    
    func loadPollutants() {
        let url = URL(string: Config.POLLUTANTS_WEB_SERVICE)!
        URLSession.shared.dataTask(with: url) { (result) in
            switch result {
            case .success( _, let data):
                // Handle Data and Response
                for (name, json) in JSON(data) {
                    self.pollutants[name] = Pollutant(name: name, json: json)
                }
                self.pollutantSelector.optionArray = Array(self.pollutants.keys).sorted()
                self.setPollutant(name: self.pollutantSelector.optionArray[0])
                break
            case .failure(let error):
                // Handle Error
                print(error)
                break
            }
        }.resume()
    }
    
    func setPollutant(name: String) {
        pollutant = pollutants[name]!
        
        self.timeResolutionSelector.optionArray = self.pollutant.getTimeResolutionNames()
        self.timeResolution = self.timeResolutionSelector.optionArray[0]
        DispatchQueue.main.async {
            self.timeResolutionSelector.text = self.timeResolution
            self.pollutantLabel.text = name + " Pollution Level"
        }
        loadThresholds(completion: loadSensors)
    }
    
    func loadThresholds(completion: @escaping () -> Void) {
        thresholds = nil
        var urlComponents = URLComponents(string: Config.THRESHOLDS_WEB_SERVICE)!
        urlComponents.queryItems = [
            URLQueryItem(name: "pollutant", value: self.pollutant.abbreviation),
            URLQueryItem(name: "time_resolution", value: Pollutant.timeResolutionAbbreviations[self.timeResolution])
        ]
        URLSession.shared.dataTask(with: urlComponents.url!) { (result) in
            switch result {
            case .success( _, let data):
                // Handle Data and Response
                let json = JSON(data)
                if !json.isEmpty {
                    self.thresholds = Thresholds(json: json)
                }
                completion()
                break
            case .failure(let error):
                // Handle Error
                print(error)
                break
            }
        }.resume()
    }

    func loadSensors() {
        // Reset sensor data
        stationarySensorReadings = [SensorReading]()
        map.removeAnnotations(map.annotations)
    
        var urlComponents = URLComponents(string: Config.SENSORS_WEB_SERVICE)!
        urlComponents.queryItems = [
            URLQueryItem(name: "pollutant", value: self.pollutant.abbreviation),
            URLQueryItem(name: "time_resolution", value: Pollutant.timeResolutionAbbreviations[self.timeResolution])
        ]
        URLSession.shared.dataTask(with: urlComponents.url!) { (result) in
            switch result {
            case .success( _, let data):
                // Handle Data and Response
                let jsonData = JSON(data)
                if jsonData.isEmpty {break}
                for sensorJSON in jsonData.array! {
                    let sensorReading = SensorReading(json: sensorJSON, name: sensorJSON["name"].stringValue, timeStamp: sensorJSON["time"].doubleValue)
                    self.stationarySensorReadings.append(sensorReading)
                    
                    DispatchQueue.main.async {
                        self.map.addAnnotation(SensorReadingAnnotation(sensorReading: sensorReading))
                    }
                }
                self.showClosestSensor()
                break
            case .failure(let error):
                // Handle Error
                print(error)
                break
            }
        }.resume()
    }
    
    func loadDroneData() {
        // Reset sensor data
        droneSensorReadings = [SensorReading]()
        map.removeAnnotations(map.annotations)
        
        let url = URL(string: Config.DRONE_DATA_WEB_SERVICE)!
        URLSession.shared.dataTask(with: url) { (result) in
            switch result {
            case .success( _, let data):
                // Handle Data and Response
                var json = JSON(data)
                for droneDataJSON in json["readings"].array! {
                    let sensorReading = SensorReading(json: droneDataJSON, name: "", timeStamp: droneDataJSON["time"].doubleValue)
                    self.droneSensorReadings.append(sensorReading)
                    DispatchQueue.main.async {
                        let annotation = SensorReadingAnnotation(sensorReading: sensorReading)
                        annotation.isDroneReading = true
                        self.map.addAnnotation(annotation)
                    }
                }
                let newPollutantName = self.getPollutantName(abbreviation: json["pollutant"].stringValue)!
                DispatchQueue.main.async {
                    self.pollutantSelector.selectedIndex = self.pollutantSelector.optionArray.firstIndex(of: newPollutantName)
                    self.pollutantSelector.text = newPollutantName
                    self.pollutantLabel.text = newPollutantName + " Pollution Level"
                }
                self.pollutant = self.pollutants[newPollutantName]
//                var date = json["date"].intValue
                break
            case .failure(let error):
                // Handle Error
                print(error)
                break
            }
            }.resume()
    }
    
    func showClosestSensor() {
        if self.stationarySensorReadings.count == 0 {self.sensorDistanceLabel.text = "Loading Sensors"; return}
        if self.userLocation == nil {self.sensorDistanceLabel.text = "Loading User Location"; return}
        
        var closest = self.stationarySensorReadings[0]
        for sensorReading in self.stationarySensorReadings {
            if self.metersFromSensor(sensorReading: sensorReading) < self.metersFromSensor(sensorReading: closest) {
                closest = sensorReading
            }
        }
        DispatchQueue.main.async {
            self.pollutionLevelLabel.text = String(format: "%.2f ppb as of %@", closest.concentration, closest.getDateString())
            self.sensorDistanceLabel.text = String(format: "Nearsest sensor: %.1f miles away", self.metersToMiles(meters: self.metersFromSensor(sensorReading: closest)))
            if self.thresholds != nil {
                let status = self.thresholds!.getStatus(concentration: closest.concentration)
                self.safetyLevelLabel.text = status.name
                self.safetyLevelLabel.textColor = UIColor(name: status.colorName)
                self.thresholdLabel.text = String(format: "(%@ ppb)", self.thresholds!.getRangeString(concentration: closest.concentration))
            } else {
                self.safetyLevelLabel.text = ""
                self.thresholdLabel.text = ""
            }
        }
    }
    
    @IBAction func reload(_ sender: Any) {
        if shouldShowDroneData {
            self.loadDroneData()
        } else {
            self.loadSensors()
        }
    }
    
    func removeDroneDataAnnotations() {
        for annotation in map.annotations {
            if annotation.title == "Drone" {
                map.removeAnnotation(annotation)
            }
        }
    }
    
    func getPollutantName(abbreviation: String) -> String? {
        for pollutant in pollutants.values {
            if pollutant.abbreviation == abbreviation {
                return pollutant.name
            }
        }
        return nil
    }
    
    func makeLabelString(gasData: [String: Any]) -> String {
        let doubleVal = (gasData["gas_concentration"] as! NSString).doubleValue
        return String(format: "%.2f ppb", doubleVal)
    }
}

// MARK: - Dropdowns
extension MainViewController {
    func setUpDropDowns() {
        //Its Id Values and its optional
        pollutantSelector.didSelect{(selectedText , index ,id) in
            self.setPollutant(name: selectedText)
        }
        pollutantSelector.selectedIndex = 0
        
        // The list of array to display. Can be changed dynamically
        timeResolutionSelector.optionArray = ["1 minute", "10 minutes", "1 hour", "8 hours", "24 hours"]
        timeResolutionSelector.didSelect{(selectedText , index ,id) in
            self.timeResolution = selectedText
            self.loadThresholds(completion: self.loadSensors)
        }
        timeResolutionSelector.selectedIndex = 0
        
        
        // The list of array to display. Can be changed dynamically
        droneDataSelector.optionArray = ["Off", "On"]
        //Its Id Values and its optional
        droneDataSelector.didSelect{(selectedText , index ,id) in
            self.shouldShowDroneData = selectedText == "On"
            if self.shouldShowDroneData {
                self.pollutantSelector.isUserInteractionEnabled = false
                self.pollutantSelector.arrowColor = UIColor(name: "light gray")!
                
                self.timeResolutionSelector.isUserInteractionEnabled = false
                self.timeResolutionSelector.arrowColor = UIColor(name: "light gray")!
                self.timeResolutionSelector.text = "N/A"
                
                self.pollutionLevelLabel.text = "Showing Drone Mission Data"
                self.safetyLevelLabel.text = ""
                self.thresholdLabel.text = ""
                self.sensorDistanceLabel.text = ""
                
                self.timeResolution = "drone"
                
                self.loadThresholds(completion: self.loadDroneData)
            } else {
                self.pollutantSelector.isUserInteractionEnabled = true
                self.pollutantSelector.arrowColor = self.droneDataSelector.arrowColor
                
                self.timeResolutionSelector.isUserInteractionEnabled = true
                self.timeResolutionSelector.arrowColor = self.droneDataSelector.arrowColor
                
                self.droneSensorReadings = [SensorReading]()
                self.removeDroneDataAnnotations()
                self.setPollutant(name: self.pollutant.name)
            }
        }
        droneDataSelector.selectedIndex = 0
    }
}

// MARK: - MKMapViewDelegate, CLLocationManagerDelegate
extension MainViewController: MKMapViewDelegate, CLLocationManagerDelegate {
    /// Start requesting user location and set map settings
    func setUpMap() {
        map.delegate = self
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
        let span = MKCoordinateSpan(latitudeDelta: 0.35, longitudeDelta: 0.35)
        let region = MKCoordinateRegion(center: newCoord, span: span)
        map.setRegion(region, animated: true)
    }
    
    /// Called when the user location changes
    func locationManager(_ manager: CLLocationManager,
                         didUpdateLocations locations: [CLLocation]){
        // Take only the most recent location
        userLocation = locations[0]
        
        // Center the map on the user, but only when the app first loads so that the user can scroll the map without it recentering on their location
        if (!hasCenteredOnUser) {
            centerMap(newCoord: userLocation!.coordinate)
            self.map.showsUserLocation = true
            hasCenteredOnUser = true
            self.showClosestSensor()
        }
    }
    
    /// Create a view for any annotation that is created
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard let annotation = annotation as? SensorReadingAnnotation else {return nil}
        var view : MKMarkerAnnotationView
        let colorName = annotation.getColorName(thresholds: thresholds)
        view = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: colorName)
        view.markerTintColor = UIColor(name: colorName)
        if colorName == "light gray" {
            view.glyphTintColor = .black
        }
        if annotation.isDroneReading {
            view.titleVisibility = .hidden
        }

        view.glyphText = String(format: "%.1f", annotation.sensorReading.concentration)
        view.animatesWhenAdded = true
        view.canShowCallout = true
        return view
    }
    
    /// Calculate the meters between the user and a given sensor
    ///
    /// - Parameter sensor: the sensor to calculate the distance from
    /// - Returns: The distance between the user and the sensor in meters
    func metersFromSensor(sensorReading: SensorReading) -> Double {
        if userLocation == nil {return 0}
        return CLLocation(
            latitude: sensorReading.location.latitude,
            longitude: sensorReading.location.longitude
        ).distance(from: userLocation!)
    }
    
    /// Find the distance from a sensor in miles
    ///
    /// - Parameter sensor: the sensor to calculate the distance from
    /// - Returns: The distance between the user and the sensor in miles
    func milesFrom(sensorReading: SensorReading) -> Double {
        return metersToMiles(meters: metersFromSensor(sensorReading: sensorReading))
    }
    
    /// Convert meters to miles
    ///
    /// - Parameter meters: A measurement in meters
    /// - Returns: The same measurement in miles
    func metersToMiles(meters: Double) -> Double {
        return meters / 1609.344
    }
    
    /// Create a graph to display when one of the sensor annotations is selected
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView){
        guard let annotation = view.annotation as? SensorReadingAnnotation else {return}
        var popUpView: UIView!
        var width: CGFloat!
        var height: CGFloat!
        
        if annotation.isDroneReading {
            popUpView = annotation.getTextView(pollutant: self.pollutant)
//            annotation.title = String(format: "Drone reading from %@", annotation.sensorReading.getDateString())
            width = 230
            height = 120
        } else {
            annotation.title = String(format: "%@ (ppb) at %@", pollutant.name, annotation.sensorReading.sensorName)
            popUpView = annotation.getChart(pollutant: self.pollutant, timeResolution: self.timeResolution)
            width = 325
            height = 130
        }
        
        let widthConstraint = NSLayoutConstraint(item: popUpView!, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: width)
        popUpView.addConstraint(widthConstraint)

        let heightConstraint = NSLayoutConstraint(item: popUpView!, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: height)
        popUpView.addConstraint(heightConstraint)
        view.detailCalloutAccessoryView = popUpView
    }
    
    func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
        guard let annotation = view.annotation as? SensorReadingAnnotation else {return}
        if annotation.isDroneReading {
            annotation.title = ""
        } else {
            annotation.title = annotation.sensorReading.sensorName
        }
    }
}
