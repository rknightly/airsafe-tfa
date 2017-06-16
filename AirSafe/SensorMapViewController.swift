//
//  SensorMapViewController.swift
//  AirSafe
//
//  Created by Ryan Knightly on 6/16/17.
//  Copyright © 2017 Ryan Knightly. All rights reserved.
//

import UIKit

class SensorMapViewController: UIViewController {
    
    @IBOutlet var sensorDescriptionLabel: UILabel!
    @IBOutlet var ppmLabel: UILabel!
    @IBOutlet var sensorDistanceLabel: UILabel!
    var nearestSensorDistance: Double!
    
    let manager = CLLocationManager()
    var hasCenteredOnUser = false
    var userLocation: CLLocation!
    @IBOutlet var map: MKMapView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadMap()
        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        // Load the sensors after the view appears so that the view is visible while the data is loading
                self.loadSensorLocations()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
