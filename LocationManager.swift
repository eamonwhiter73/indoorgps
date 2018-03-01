//
//  LocationManager.swift
//  onebeacon
//
//  Created by Eamon White on 2/24/18.
//  Copyright © 2018 EamonWhite. All rights reserved.
//

import Foundation
import CoreLocation

protocol LocationManagerDelegate: class {
    func locationManagerDidUpdateLocation(_ locationManager: CLLocationManager, location: CLLocation)
    func locationManagerDidUpdateHeading(_ locationManager: CLLocationManager, heading: CLHeading, accuracy: CLLocationDirection)
    func locationManagerDidEnterRegion(_ locationManager: CLLocationManager, didEnterRegion region: CLRegion)
    func locationManagerDidExitRegion(_ locationManager: CLLocationManager, didExitRegion region: CLRegion)
    func locationManagerDidDetermineState(_ locationManager: CLLocationManager, didDetermineState state: CLRegionState, region: CLRegion)
    func locationManagerDidRangeBeacons(_ locationManager: CLLocationManager, beacons: [CLBeacon], region: CLBeaconRegion)
}


class LocationManager: NSObject, CLLocationManagerDelegate {
    var locationManager: CLLocationManager!
    weak var delegate: LocationManagerDelegate?
    var beaconsToRange: [CLBeaconRegion]
    var currentLocation: CLLocation!

    override init() {
        self.beaconsToRange = []
        super.init()
        
        self.locationManager = CLLocationManager()
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        self.locationManager.distanceFilter = kCLDistanceFilterNone
        self.locationManager.headingFilter = kCLHeadingFilterNone
        self.locationManager.pausesLocationUpdatesAutomatically = true
        self.locationManager.delegate = self
        
        self.enableLocationServices()
    }
    
    func enableLocationServices() {
        self.checkStatus(status: CLLocationManager.authorizationStatus(), change: false)
    }
    
    func checkStatus(status: CLAuthorizationStatus, change: Bool) {
        switch status {
        case .notDetermined:
            // Request when-in-use authorization initially
            locationManager.requestAlwaysAuthorization()
            break
            
        case .restricted, .denied:
            // Disable location features
            print("send an alert that the app will not function")
            break
            
        case .authorizedWhenInUse:
            locationManager.requestAlwaysAuthorization()
            // Enable basic location features
            break
            
        case .authorizedAlways:
            if !change {
                locationManager.startUpdatingLocation()
                locationManager.startUpdatingHeading()
                self.monitorBeacons()
            }
            // Enable any of your app's location features
            break
        }
    }
    
    func monitorBeacons() {
        print("monitorBeacons()")
        if CLLocationManager.isMonitoringAvailable(for:
            CLBeaconRegion.self) {
            print("monitorBeacons().monitoringIsAvailable")
            // Match all beacons with the specified UUID
            let proximityUUIDA = UUID(uuidString:
                "12345678-B644-4520-8F0C-720EAF059935")
            let proximityUUIDB = UUID(uuidString:
                "E2C56DB5-DFFB-48D2-B060-D0F5A71096E0")
            
            let beaconRegionD = CLBeaconRegion(
                proximityUUID: proximityUUIDB!,
                major: 0x0001,
                minor: 0x0004,
                identifier: "locationA")
            
            let beaconRegionE = CLBeaconRegion(
                proximityUUID: proximityUUIDB!,
                major: 0x0001,
                minor: 0x0002,
                identifier: "locationB")
            
            let beaconRegionF = CLBeaconRegion(
                proximityUUID: proximityUUIDB!,
                major: 0x0001,
                minor: 0x0005,
                identifier: "locationC")
            
            self.locationManager?.startMonitoring(for: beaconRegionD)
            self.locationManager?.startMonitoring(for: beaconRegionE)
            self.locationManager?.startMonitoring(for: beaconRegionF)
            

            print("\(String(describing: self.locationManager?.monitoredRegions)) + monitoredRegions")
        }
    }
    
    //MARK: - CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        for location in locations {
            self.delegate?.locationManagerDidUpdateLocation(self.locationManager, location: location)
        }
        
        self.currentLocation = manager.location
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        self.delegate?.locationManagerDidUpdateHeading(self.locationManager, heading: newHeading, accuracy: newHeading.headingAccuracy)
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        if region is CLBeaconRegion {
            // Start ranging only if the feature is available.
            if CLLocationManager.isRangingAvailable() {
                locationManager?.startRangingBeacons(in: region as! CLBeaconRegion)
                
                // Store the beacon so that ranging can be stopped on demand.
                beaconsToRange.append(region as! CLBeaconRegion)
            }
        }
        self.delegate?.locationManagerDidEnterRegion(self.locationManager, didEnterRegion: region)
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        self.delegate?.locationManagerDidExitRegion(self.locationManager, didExitRegion: region)
    }
    
    func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion) {
        if region is CLBeaconRegion {
            print("determined state of beacon for region - \(region)")
            // Start ranging only if the feature is available.
            if CLLocationManager.isRangingAvailable() {
                print("determined state of beacon and started ranging")
                locationManager?.startRangingBeacons(in: region as! CLBeaconRegion)
                // Store the beacon so that ranging can be stopped on demand.
                beaconsToRange.append(region as! CLBeaconRegion)
            }
        }
        
        self.delegate?.locationManagerDidDetermineState(self.locationManager, didDetermineState: state, region: region)
    }
    
    func locationManager(_ manager: CLLocationManager,
                         didRangeBeacons beacons: [CLBeacon],
                         in region: CLBeaconRegion) {

        self.delegate?.locationManagerDidRangeBeacons(self.locationManager, beacons: beacons, region: region)
    }
    
    func locationManager(_ manager: CLLocationManager,
                         didChangeAuthorization status: CLAuthorizationStatus) {
        print("authorization changed --- \(String(describing: CLLocationManager.authorizationStatus()))")
        self.checkStatus(status: status, change: true)
    }
    
    func locationManagerShouldDisplayHeadingCalibration(_ manager: CLLocationManager) -> Bool {
        return true
    }
}
