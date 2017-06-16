//
//  AppDelegate.swift
//  AirSafe TFA
//
//  Created by Ryan Knightly on 5/26/17.
//  Copyright © 2017 Ryan Knightly. All rights reserved.
//

import UIKit
import UserNotifications
import CocoaMQTT

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var backgroundMessageReceived = false
    var wasNotificationSent = false // Whether a notification was sent during the current background session

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        let settings = UIUserNotificationSettings(types: UIUserNotificationType.alert, categories: nil)
        UIApplication.shared.registerUserNotificationSettings(settings)
        UIApplication.shared.setMinimumBackgroundFetchInterval(UIApplicationBackgroundFetchIntervalMinimum)
        return true;
    }


    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        RKClient.disconnect()
        
        wasNotificationSent = false
        RKMQTTConnectionManager.setDelegate(delegate: self)
    }
    
    /// Send the user a notification that warns of high current gas levels
    ///
    /// - Parameter ppm: the detected gas level to tell the user
    func sendNotification(ppm: Double) {
        let localNotification:UILocalNotification = UILocalNotification()
        localNotification.alertBody = "Unsafe Gas Levels Detected: " + String(RKMathOperations.shortened(num: ppm))  + " ppm Methane"
        localNotification.fireDate = NSDate(timeIntervalSinceNow: 1) as Date
        UIApplication.shared.scheduleLocalNotification(localNotification)
        
        wasNotificationSent = true
    }
    
    /// Opens an MQTT connection if none exists and waits for a few seconds before completing
    /// Run at each fetch
    func application(_ application: UIApplication,
                              performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        print("fetching")
        backgroundMessageReceived = false
        RKMQTTConnectionManager.createConnectionIfNecessary()
        // TODO: further examine whether wait should be 4 or 5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(4), execute: {
            print("finished")
            // Put your code which should be executed with a delay here
            if self.backgroundMessageReceived {
                print("Completed with data received")
                completionHandler(UIBackgroundFetchResult.newData)
            } else {
                print("No data")
                completionHandler(UIBackgroundFetchResult.noData)
            }
        })
        
        
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
        
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        print("Sending notification to transfer responsibility")
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "returnMQTTDelegateResponsibility"), object: nil)
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    func returnMQTTDelegateResponsibility() {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "returnMQTTDelegateResponsibility"), object: nil)
    }
}

extension AppDelegate: CocoaMQTTDelegate {
    func mqtt(_ mqtt: CocoaMQTT, didConnect host: String, port: Int) {
        print("didConnect \(host):\(port)")
        mqtt.subscribe("Sensor1/ppmv") // TODO: use previous topic
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didReceiveMessage message: CocoaMQTTMessage, id: UInt16 ) {
        // Only send one notification even if multiple messages are received during fetch
        print("Message reveived")
        if let msgDouble = Double(message.string!) {
            if RKConditions.isDangerous(ppm: msgDouble) && !wasNotificationSent {
                sendNotification(ppm: RKMathOperations.shortened(num: msgDouble))
            }
        }
        backgroundMessageReceived = true
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

