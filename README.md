# AirSafe TFA

AirSafe is an iOS application written in Swift that displays gas sensor locations and observations from the present and the past. This app is the simple community-facing end of an environmental research project being done between Rice University and Technology For All.

Screenshots and more information about the app features can be found [here](http://airsafe-tfa.weebly.com) as well as on the app store.

## Motivation

Real-time environmental data of such high granularity did not exist at a publicly-available level, and this mobile application brings such real-time readings to community members in a simple and accessible format, as well as providing notifications if they should be concerned by the safety level indicated by the current sensor readings.

## Dependencies

#### Installed via CocoaPods
* CocoaMQTT- to receive live sensor data from the MQTT broker
* SwiftChart- to display the past observations in easily-readable line graphs

#### Manually Installed
* MongoKitten- to connect to the MongoDB server, which contains information about the different sensors as well as their past observations.

**Note**: MongoKitten had to be manually installed because it is a MacOS library using the Swift Package Manager, and this is an iOS project using CocoaPods, so it isn't compatible for an automatic installation.

## Installation

Download and open in Xcode via AirSafe.xcworkspace. This is necessary because of the use of CocoaPods, for the pods are viewed as their own project, which is held together with AirSafe under the workspace.

Because I checked in the CocoaPod files to version control, you will not have to run 'pod install', as all of the files will already be present.

However, do note that there is one file not checked into public version control, Secrets.swift. This is for security purposes and in order to successfully build the app, the file will need to be obtained by requesting it from the repository owner.

## Future goals

* Adding push notifications when dangerous conditions are observed by a nearby sensor
* Adding unit test coverage
* Creating an Android version
