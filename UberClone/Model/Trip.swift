//
//  Trip.swift
//  UberClone
//
//  Created by Mysticre on 2022/2/3.
//

import Foundation
import MapKit
import CoreLocation

//struct object的概念基本就是將database的資料格式整理成object的樣子,方便app使用/後續整理 database的資料
//依照json的概念編制struct, node -> child
//以Database的大分支 "Trip"為命名
struct Trip {
    let passengerUid: String!
    let driverUid: String? //driver尚可不參與init
    var pickupCoordinate: CLLocationCoordinate2D! //座標資料包含經緯度(lat 和 lon)
    var destinationCoordinate: CLLocationCoordinate2D!
    var state: TripState! //用enum Type表示
    //uid獨立出來, 其餘以dictionary表示
    init (passengerUid: String, dictionary:[String:Any]){
        self.passengerUid = passengerUid
        self.driverUid = dictionary["driverUid"] as? String ?? " "
        if let pickupCoordinates = dictionary["pickupCoordinate"] as? NSArray{
            guard let lat = pickupCoordinates[0] as? CLLocationDegrees else {return}
            guard let lon = pickupCoordinates[1] as? CLLocationDegrees else {return}
            //包裝成CLLocation的形式
            self.pickupCoordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        }
        if let destinationCoordinates = dictionary["destinationCoordinate"] as? NSArray {
            guard let lat = destinationCoordinates[0] as? CLLocationDegrees else {return}
            guard let lon = destinationCoordinates[1] as? CLLocationDegrees else {return}
            self.destinationCoordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        }
        //State狀態用enum裡面的rawValue來儲存
        if let stateIndex = dictionary["state"] as? Int {
            self.state = TripState(rawValue: stateIndex)
        }
    }
}
//再一個建立 enum表示 state的不同狀態 後面使用int protocol 才可用rawValue表示enum狀態
enum TripState: Int {
    case requested
    case denied
    case accepted
    case driverArrived
    case inProgress
    case arrivedAtDestination
    case completed
}


