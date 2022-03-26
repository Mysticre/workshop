//
//  DriverAnnotation.swift
//  UberClone
//
//  Created by Mysticre on 2022/1/7.
//

import Foundation
import MapKit

//物件化的MKAnnotation
class DriverAnnotation: NSObject, MKAnnotation {
    //MKAnnotation 都一定會有Coordinate2D, uid則為客製化自行添加
    //要將變數寫dynamic var 才會即時更新而無需重啟app
    dynamic var coordinate: CLLocationCoordinate2D
    var uid: String
    init(uid:String, coordinate:CLLocationCoordinate2D) {
        self.uid = uid
        self.coordinate = coordinate
    }
    
    func updatedAnnotationCoordinate(withcoordinate coordinate: CLLocationCoordinate2D) {
        UIView.animate(withDuration: 0.2) {
            self.coordinate = coordinate
        }
    }
}
