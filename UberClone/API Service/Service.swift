//
//  Service.swift
//  UberClone
//
//  Created by Mysticre on 2022/1/2.
//

import Foundation
import Firebase
import GeoFire

// MARK: - Database Reference

//建立Database的全域Reference與child語法
let DB_REF = Database.database().reference()
let REF_USERS = DB_REF.child("users")
let REF_DRIVER_LOCATIONS = DB_REF.child("driver-location")
let REF_TRIP = DB_REF.child("trips")

// MARK: - DrvierServiece API
struct DriverService {
    static let shared = DriverService()
    //建立監聽Trip功能後把它裝回Trip物件內,供Driver/Passenger使用
    func observeTripForDriver(completion: @escaping(Trip) -> Void){
        //這邊是要監聽整個Trip分類內所有的狀態
        REF_TRIP.observe(.childAdded) { (snapshot) in
            guard let dictionary = snapshot.value as? [String:Any] else { return }
            let uid = snapshot.key
            let tripConstruction = Trip(passengerUid: uid, dictionary: dictionary)
            completion(tripConstruction)
        }
    }
    
    func acceptTrip(trip: Trip, completion:@escaping(Error?, DatabaseReference)->Void) {
        guard let uid = Auth.auth().currentUser?.uid else {return}
        let values = ["driverUid" : uid,
                            "state":TripState.accepted.rawValue] as [String : Any]
        
        REF_TRIP.child(trip.passengerUid).updateChildValues(values, withCompletionBlock: completion)
    }
    
    //driver提示passenger取消後的提示
    func observeTripRemoved(_ trip:Trip, completion:@escaping() -> Void) {
        REF_TRIP.child(trip.passengerUid).observeSingleEvent(of: .childRemoved) { (snapshot) in
            completion() //Escaping空的Completion
        }
    }
    
    //更新Trip的State狀態
    func updateTripState(trip: Trip, state: TripState, completion:@escaping(Error?, DatabaseReference) -> Void) {
        REF_TRIP.child(trip.passengerUid).child("state").setValue( state.rawValue, withCompletionBlock: completion)
        if state == .completed {
            REF_TRIP.child(trip.passengerUid).removeAllObservers()
        }
    }
    
    func updatedDriverLocation(location: CLLocation) {
        guard let uid = Auth.auth().currentUser?.uid else {return}
        let geo = GeoFire(firebaseRef: REF_DRIVER_LOCATIONS)
        geo.setLocation(location, forKey: uid)
    }
}

//MARK: - Passenger API
struct PassengerService {
    static let shared = PassengerService()
    //搜尋資料庫中Driver的資料 -> 找到整包資料中的Uid 和座標位置 -> 篩選出User當前範圍內的Driver座標資料
    //選出Driver的資料後,再將User資料存在User Object裡面,供HomeController使用
    func fetchDriverData (location: CLLocation, completion: @escaping(User) -> Void) {
        let geo = GeoFire(firebaseRef: REF_DRIVER_LOCATIONS)
        //包裝在Geo內的DriverUid和Location要在Query的座標內(KeyEnter),50單位的範圍內出現
        //Observe要加,with 不然會出現 Ambiguous use of 'observe'
        //Observe會持續監聽資料庫狀態,有改變就會重新執行程式內容;ObserveSingleEvent只有撈取一次
        REF_DRIVER_LOCATIONS.observe(.value) { (snapshot) in
            geo.query(at: location, withRadius: 50).observe(.keyEntered, with: { (uid, location) in
                Service.shared.fetchUserData(currentUid: uid) { (user) in
                    //在User Object內創一個Location變數來存放Location的資料,但User是Struct不能assign 因此替換變數名稱為driver
                    var driver = user
                    driver.location = location
                    completion(driver)
                }
            })
        }
    }
    
    //要將座標傳到Database,所以需透過參數座標位置
    func updateTrip( _ pickupCoordinate: CLLocationCoordinate2D, _ destination:CLLocationCoordinate2D, completion: @escaping(Error?, DatabaseReference) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let pickupArray =  [pickupCoordinate.latitude, pickupCoordinate.longitude]
        let destinationArray = [destination.latitude, destination.longitude]
        //確認Uid -> 建立ReferenceTrip -> 將座標整理成Dictionary的格式上傳到Database
        let values = ["pickupCoordinate": pickupArray,
                      "destinationCoordinate": destinationArray,
                      "state": TripState.requested.rawValue] as [String : Any]
        //把CompletionHandler用參數取代原本的CompletionBlock,並填入一樣的原內容
        //上傳完成後跑出Error and Reference的程式碼確認狀態
        //上傳完後就要記得整理成Object的狀態
        REF_TRIP.child(uid).updateChildValues(values, withCompletionBlock: completion)
    }
    
    func observeTripForPassenger(completion: @escaping(Trip) -> Void) {
        //這邊是只要監聽該Trip分類的特定Uid內的Trip狀態 所以要先拿取Uid
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        REF_TRIP.child(uid).observe(.value) { (snapshot) in
            guard let dic = snapshot.value as? [String:Any] else { return }
            let uidForTrip = snapshot.key
            //取出完畢後construct為物件
            let trip = Trip(passengerUid: uidForTrip, dictionary: dic)
            //在彈出completion
            completion(trip)
        }
    }
    
    //passenger取消
    func deleteTrip(completion:@escaping(Error?, DatabaseReference) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {return}
        
        REF_TRIP.child(uid).removeValue(completionBlock: completion)
    }
    
    func saveLocation(locationString:String, type: LocationType, completion: @escaping(Error?,DatabaseReference) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {return}
        let key = type.rawValue == 0 ? "home" : "work" as String
        
        REF_USERS.child(uid).child(key).setValue(locationString, withCompletionBlock: completion)
    }
}

//MARK: - Shared API
struct Service {
    static let shared = Service()
    
    func fetchUserData(currentUid: String, completion: @escaping(User) -> Void) {
        REF_USERS.child(currentUid).observeSingleEvent(of: .value) { snapshot in
            guard let currentData = snapshot.value as? [String:Any] else {return}
            let uid = snapshot.key
            let userData = User(uid: uid, dictionary: currentData)
            //用complition跳出資料型態為User的userData值
            completion(userData)
        }
    }
}



        
        
    


