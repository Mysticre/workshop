//
//  LocationHandler.swift
//  UberClone
//
//  Created by Mysticre on 2022/1/4.
//

import Foundation
import CoreLocation

//class物件化,使用物件NSObject,並使用 init()
class LocationHandler: NSObject, CLLocationManagerDelegate {
//MARK: - Properties
    static let shared = LocationHandler()
    var location: CLLocation?
    var locationManager: CLLocationManager!
    
//MARK: - LifeCycle
    override init() {
        super.init()
        locationManager = CLLocationManager()
        locationManager.delegate = self
    }
    
//MARK: - Helper Functions
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse{
            locationManager.requestAlwaysAuthorization()
        }
    }
}
