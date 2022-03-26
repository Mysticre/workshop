//
//  HomeController.swift
//  UberClone
//
//  Created by Mysticre on 2021/11/30.
//

import Foundation
import UIKit
import Firebase
import MapKit
import CoreLocation

protocol HomeControllerDelegate: class {
    func handleMenuToggle()
}

private enum ActionButtonConfiguration {
    case showMenu
    case dismissActionView
    
    init() {
        self = .showMenu
    }
}

private enum AnnotationType: String {
    case pickup
    case destination
}

private let reuseIdentifier = "LocationCell"
private let reuseAnnotation = "DriverAnnotation"

class HomeController: UIViewController {
    //MARK: - Properties
    weak var delegate: HomeControllerDelegate?
    private let locationInputViewHeight: CGFloat = 200
    private let rideActionViewHeight: CGFloat = 300
    private let mapView = MKMapView()
    private let locationManager = LocationHandler.shared.locationManager
    private let inputActivationView = LocationInputActivationView()
    private let locationInputView =  LocationInputView()
    private let tableView = UITableView()
    private var actionButtonConfiguration = ActionButtonConfiguration()
    private let rideActionView = RideActionView()
    //用ComputedProperty傳送資料到NameLabel
    var userData: User? {
        didSet{
            locationInputView.inputTitleLabel = userData
            if userData?.accountType == .passenger {
                fetchDriverData()
                configureLocationActivationView()
                observeTripForPassenger()
                savedLocation()
            }else{
                observeTripForDriver()
            }
        }
    }
    
    var tripData: Trip? {
        didSet {
            guard let userData = userData else {return}
            if userData.accountType == .driver{
                if let tripData = tripData{
                    let controller = PickupController(trip: tripData)
                    controller.delegate = self
                    controller.modalPresentationStyle = .fullScreen
                    self.present(controller, animated: true, completion: nil)
                } else {
                    print("DEBUG: Show rideActionView here")
                }
            }
        }
    }
    private var route: MKRoute?
    //將搜尋結果的placemark存入
    private var searchResults = [MKPlacemark]()
    //將儲存結果的placemark存入
    private var savedResults = [MKPlacemark]()
    
    private let actionButton: UIButton = {
        let button = UIButton()
        button.setImage(#imageLiteral(resourceName: "baseline_menu_black_36dp").withTintColor(.white, renderingMode: .alwaysOriginal),for: .normal)
        button.addTarget(self, action: #selector(settingButtonClick), for: .touchUpInside)
        return button
    }()
    
    //MARK: - LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        configureRideActionView()
    }
    
    //MARK: - Driver API
    func observeTripForDriver() {
        DriverService.shared.observeTripForDriver { trip in
            self.tripData = trip
        }
    }
    
    func observeCancelledTrip(trip:Trip) {
        DriverService.shared.observeTripRemoved(trip) {
            self.removeAnnotationAndPolyline()
            self.showRideActionView(shouldShow: false)
            self.presentAlertController("哎呀！乘客取消了！", message: "乘客取消了此次乘載任務，請按下「確認」返回。")
            self.centerMapOnUserLocation()
        }
    }
    
    //MARK: - Passenger API
    func fetchDriverData() {
        guard let location = locationManager?.location else {return}
        PassengerService.shared.fetchDriverData(location: location) { (driver) in
            guard let coordinate = driver.location?.coordinate else {return}
            let annotation = DriverAnnotation(uid: driver.uid, coordinate: coordinate)
            print("DEBUG:Driver Coordinate is \(coordinate)")
            //設定一個ComputeProperty來設計布林判斷變數
            var isDriverVisible: Bool {
                //判斷Mapview的Annotation是不是由下列程式碼給予的條件進行篩選
                return self.mapView.annotations.contains { (annotation) -> Bool in
                    //Escaping出來的Annotation -> 是否為該Annotation的條件
                    guard let driverAnno = annotation as? DriverAnnotation else {return false}
                    if driverAnno.uid == driver.uid {
                        //是的話就更新新的座標位置到DriverAnnotation裡面
                        driverAnno.updatedAnnotationCoordinate(withcoordinate: coordinate)
                        //新增聚焦兩點距離的Function 用UserObject的內容給予Uid確認
                        self.zoomActiveTrip(withDriverUid: driver.uid)
                        return true
                    }
                    return false
                }
            }
            if !isDriverVisible {
                self.mapView.addAnnotation(annotation)
            }
        }
    }
    
    func observeTripForPassenger() {
        PassengerService.shared.observeTripForPassenger { trip in
            self.tripData = trip
            //Switch的參數要先為非optional的狀態才能把所有結果呼叫出來
            guard let state = trip.state else {return}
            //用FetchUser功能拿取Driver的資料
            guard let driverUid = trip.driverUid else {return}
            switch state {
            case .requested:
                break
            case .denied:
                self.ShouldPresentLoadingView(false)
                self.presentAlertController("糟糕！", message: "目前並無可提供載運服務的司機，請稍待片刻再試一次！")
                PassengerService.shared.deleteTrip { (err, ref) in
                    self.centerMapOnUserLocation()
                    self.inputActivationView.alpha = 1
                    self.configureActionButton(configState: .showMenu)
                    self.removeAnnotationAndPolyline()
                }
            case .accepted:
                self.ShouldPresentLoadingView(false)
                self.removeAnnotationAndPolyline()
                self.zoomActiveTrip(withDriverUid: driverUid)
                Service.shared.fetchUserData(currentUid: driverUid) { (driver) in
                    self.showRideActionView(shouldShow: true, config: .tripAccepted, userData: driver)
                }
            case .driverArrived:
                self.rideActionView.configureUI(withConfig: .driverArrived)
            case .inProgress:
                self.rideActionView.configureUI(withConfig: .tripInProgress)
            case .arrivedAtDestination:
                self.rideActionView.configureUI(withConfig: .tripInProgress)
            case .completed:
                PassengerService.shared.deleteTrip { (err, ref) in
                    self.showRideActionView(shouldShow: false)
                    self.centerMapOnUserLocation()
                    self.configureActionButton(configState: .showMenu)
                    self.presentAlertController("已達目的地", message: "感謝搭乘！希望您有個愉快的一天")
                    self.inputActivationView.alpha = 1
                }
            }
        }
    }
    
    func startTrip() {
        guard let tripData = tripData else {return}
        DriverService.shared.updateTripState(trip: tripData, state: .inProgress) { (err, ref) in
            self.rideActionView.configureUI(withConfig: .tripInProgress)
            self.removeAnnotationAndPolyline()
            self.mapView.generateAnnotation(withCoordinates: tripData.destinationCoordinate)
            self.setCustomRegion(type: .destination, coordintes: tripData.destinationCoordinate)
            
            let placemark = MKPlacemark(coordinate: tripData.destinationCoordinate)
            let mapItem = MKMapItem(placemark: placemark)
            self.generatePolyline(toDestination: mapItem)
        }
    }
    
    //MARK: - Helper Functions
    func configureUI() {
        configureMapView()
        configureNaviBar()
    }
    
    func configureNaviBar() {
        navigationController?.isNavigationBarHidden = true
        navigationController?.navigationBar.barStyle = .black
    }
    
    func configureMapView() {
        //將該View加入Mapview才可顯示Map,另外限定Mapview的邊框為Superview的範圍
        view.addSubview(mapView)
        mapView.frame = view.frame
        enableLocationManager()
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .follow
        mapView.tintColor = UIColor.customColor(red: 10, green: 193, blue: 104)
        mapView.delegate = self
        
        view.addSubview(actionButton)
        actionButton.anchor(top:view.safeAreaLayoutGuide.topAnchor, left: view.leftAnchor, paddingLeft: 12)
        actionButton.setDimensions(height: 30, width: 30)
    }
    
    func configureLocationInputView() {
        //由該Protocal的創造方使用並將該HomeController儲存至此
        locationInputView.delegate = self
        view.addSubview(locationInputView)
        locationInputView.anchor(top:view.topAnchor, left: view.leftAnchor, right:view.rightAnchor, height:locationInputViewHeight)
        locationInputView.alpha = 0
        UIView.animate(withDuration: 0.5) {
            self.locationInputView.alpha = 1
        } completion: { _ in
            UIView.animate(withDuration: 0.3) {
                self.tableView.frame.origin.y = self.locationInputViewHeight
            }
        }
    }
    
    func configureLocationActivationView() {
        //由該Protocal的創造方使用並將該HomeController儲存至此
        inputActivationView.delegate = self
        //加入在這個View當中
        view.addSubview(inputActivationView)
        inputActivationView.centerX(inView: view)
        inputActivationView.anchor(top:view.safeAreaLayoutGuide.topAnchor, paddingTop: 50)
        //可以用view.frame.width來標示寬度
        inputActivationView.setDimensions(height:50 , width:view.frame.width - 64)
        //先消失後,再用UIView.animate慢慢顯示出來
        inputActivationView.alpha = 0
        UIView.animate(withDuration: 2) {
            self.inputActivationView.alpha = 1
        }
    }
    
    func configureTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = .white
        tableView.register(LocationInputCell.self, forCellReuseIdentifier: reuseIdentifier)
        tableView.rowHeight = 60
        let height = view.frame.height - locationInputViewHeight
        //表示從y軸的底(畫面框的下方)往上的某個位置開始
        tableView.frame = CGRect(x: 0, y: view.frame.height, width: view.frame.width, height: height)
        tableView.tableFooterView = UIView()
        view.addSubview(tableView)
    }
    
    func configureDismissLocationInputView(completion: ((Bool) -> Void)? = nil) {
        UIView.animate(withDuration: 0.4, animations: {
            self.locationInputView.alpha = 0
            //Y軸座標拉回到畫面的底部
            self.tableView.frame.origin.y = self.view.frame.height
            //一次全部移除不要再疊加
            self.locationInputView.removeFromSuperview()
        }, completion: completion)
    }
    
    fileprivate func configureActionButton(configState: ActionButtonConfiguration) {
        switch configState{
        case .showMenu:
            actionButton.setImage(#imageLiteral(resourceName: "baseline_menu_black_36dp").withTintColor(.white, renderingMode: .alwaysOriginal), for: .normal)
            actionButtonConfiguration = .showMenu
        case .dismissActionView:
            actionButton.setImage(#imageLiteral(resourceName: "baseline_arrow_back_black_36dp-1").withTintColor(.white, renderingMode: .alwaysOriginal), for: .normal)
            actionButtonConfiguration = .dismissActionView
        }
    }
    
    func configureRideActionView() {
        rideActionView.delegate = self
        view.addSubview(rideActionView)
        rideActionView.frame = CGRect(x:0 , y: view.frame.height, width:view.frame.width , height: rideActionViewHeight)
    }
    
    func showRideActionView(shouldShow: Bool, destination: MKPlacemark? = nil, config: RideActionViewConfuguration? = nil, userData:User? = nil) {
        let yAxisShouldShow = shouldShow ? self.view.frame.height - self.rideActionViewHeight : self.view.frame.height
        UIView.animate(withDuration: 0.6) {
            self.rideActionView.frame.origin.y = yAxisShouldShow
        }
        if let userData = userData {
            self.rideActionView.userData = userData
        }
        self.rideActionView.destination = destination
        if let config = config {
            self.rideActionView.configureUI(withConfig: config)
        }
    }
    
    func savedLocation() {
        guard let userData = userData else {return}
        savedResults.removeAll()
        if let home = userData.home {
            geoCoder(addressString: home)
        }
        if let work = userData.work{
            geoCoder(addressString: work)
        }
    }
    
    func geoCoder(addressString: String) {
        //可將座標位置轉文字相互轉換給使用者
        let geoCoder = CLGeocoder()
        geoCoder.geocodeAddressString(addressString) { (placemarks, err) in
            //先轉換CLPlaceMark到MKPlaceMark
            guard let clPlacemark = placemarks?.first else {return}
            let placemark = MKPlacemark(placemark: clPlacemark)
            self.savedResults.append(placemark)
            self.tableView.reloadData()
        }
    }
    
    //MARK:- Selectors
    @objc func settingButtonClick() {
        switch actionButtonConfiguration {
        case .showMenu:
            delegate?.handleMenuToggle()
        case .dismissActionView:
            removeAnnotationAndPolyline()
            UIView.animate(withDuration: 0.8) {
                self.inputActivationView.alpha = 1
                self.actionButtonConfiguration = .showMenu
                self.actionButton.setImage(#imageLiteral(resourceName: "baseline_menu_black_36dp").withTintColor(.white, renderingMode: .alwaysOriginal), for: .normal)
                self.showRideActionView(shouldShow: false)
            }
            //回到user的起始地點
            self.mapView.setUserTrackingMode(.follow, animated: true)
        }
    }
}

//MARK: - CLLocationManagerDelegate
//首先增加讓CLLocation使用用戶座標的權限確認狀態
extension HomeController: CLLocationManagerDelegate {
    //LocationManager開啟監控Region位置的功能
    func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
        if region.identifier == AnnotationType.pickup.rawValue {
            print("DEBUG: did start monitoring pickup region \(region)")
        }else{
            print("DEBUG:did start monitoring destination region \(region)")
        }
    }
    
    //Location Manager開啟監控進入觀測圈region位置的功能
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        guard let trip = tripData else {return}
        if region.identifier == AnnotationType.pickup.rawValue {
            DriverService.shared.updateTripState(trip: trip, state: .driverArrived) { (err, ref) in
                self.rideActionView.configureUI(withConfig: .pickupPassenger)
            }
        }
        if region.identifier == AnnotationType.destination.rawValue {
            DriverService.shared.updateTripState(trip: trip, state: .arrivedAtDestination) { (err, ref) in
                self.rideActionView.configureUI(withConfig: .endTrip)
            }
        }
    }
    
    func enableLocationManager() {
        locationManager?.delegate = self
        switch locationManager?.authorizationStatus {
        case .notDetermined:
            print("DEBUG: Not determined...")
            locationManager?.requestWhenInUseAuthorization()
        case .restricted, .denied:
            break
        case .authorizedAlways:
            print("DEBUG:Auth Always")
            locationManager?.startUpdatingLocation()
            locationManager?.desiredAccuracy = kCLLocationAccuracyBest //(要有一個可存等級的變數)
        case .authorizedWhenInUse:
            print("DEBUG:Auth when in use")
            locationManager?.requestAlwaysAuthorization()
            locationManager?.desiredAccuracy = kCLLocationAccuracyBest
        case .none:
            break
        @unknown default:
            break
        }
    }
}

//MARK: - LocationInputActivationViewDelegate
extension HomeController: LocationInputActivationViewDelegate {
    func presentLocationInputView() {
        inputActivationView.alpha = 0
        configureLocationInputView()
        configureTableView()
    }
}

//MARK: - LocationInputViewDelegate
extension HomeController: LocationInputViewDelegate {
    //將textField的queryText透過Delegate傳到HomeController執行searchBy
    func executeSearch(text: String) {
        searchBy(queryText: text) { (result) in
            self.searchResults = result
            self.tableView.reloadData()
        }
    }
    
    func dismissLocationInputView() {
        configureDismissLocationInputView { _ in
            UIView.animate(withDuration: 0.5) {
                self.inputActivationView.alpha = 1
            }
        }
    }
}

//MARK: - UITableviewDelegate
extension HomeController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        //拆成2個section (序號0跟1)
        return 2
    }
    
    //分割部分的標題
    //    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    //        return section == 0 ? "已儲存的地址" : "搜尋結果"
    //    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView()
        view.backgroundColor = UIColor.customColor(red: 39, green: 118, blue: 80)
        
        let label = UILabel()
        if section == 0 {
            label.text = "已儲存的地址"
        } else{
            label.text = "搜尋結果"
        }
        label.font = UIFont.systemFont(ofSize: 18)
        label.textColor = .white
        
        view.addSubview(label)
        label.centerY(inView: view)
        label.anchor(left: view.leftAnchor, paddingLeft: 12)
        return view
    }
    
    //回傳每個分割部分的格數
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //表示在第一部分的格子數 存在第一部分就回傳2 其餘就回傳searchResults.count的個數
        return section == 0  ?  savedResults.count : searchResults.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath) as! LocationInputCell //要cast為LocationInputCell
        cell.backgroundColor = .white
        if indexPath.section == 0 {
            cell.placemarks = savedResults[indexPath.row]
        }
        if indexPath.section == 1 {
            cell.placemarks = searchResults[indexPath.row]
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //建立新的變數表示searchResults在每一列的值,再初始化annotation與儲存其選定位置之座標
        let selectedPlacemark = indexPath.section == 0 ? self.savedResults[indexPath.row] : self.searchResults[indexPath.row]
        configureActionButton(configState: .dismissActionView)
        //要先把selectedPlacemark裝成MapItem再放進generatePolyline Function內
        let destination = MKMapItem(placemark: selectedPlacemark)
        generatePolyline(toDestination: destination)
        configureDismissLocationInputView { ( _ ) in
            self.mapView.generateAnnotation(withCoordinates: selectedPlacemark.coordinate)
            //用高階函數修改 -> "filter( {執行} )" 篩選非(!)DriverAnnotation class(isKind)的物件, $0為1號參數, trailing寫法 {($0)}
            let annoCollective = self.mapView.annotations.filter({ !$0.isKind(of: DriverAnnotation.self)})
            
            //            self.mapView.annotations.forEach { (annotation) in
            //                if let anno = annotation as? MKUserLocation {
            //                    annoCollective.append(anno)
            //                }
            //                if let anno = annotation as? MKPointAnnotation{
            //                    annoCollective.append(anno)
            //                }
            //            }
            
            //放大Array內的兩個點
            self.mapView.zoomInMap(annotationsInRect: annoCollective)
            //切換RideActionView狀態
            self.showRideActionView(shouldShow: true, destination: selectedPlacemark, config: .requestRide)
        }
    }
}


//MARK: - MKMapViewDelegate
extension HomeController: MKMapViewDelegate {
    //可隨時更新driver位置的function
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        guard let userData = userData else {return}
        if userData.accountType == .driver {
            guard let location = userLocation.location else {return}
            DriverService.shared.updatedDriverLocation(location: location)
        }
    }
    
    //可用客製化annotation的function
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if let annotation = annotation as? DriverAnnotation{
            let view = MKAnnotationView(annotation: annotation, reuseIdentifier: reuseAnnotation)
            view.image = #imageLiteral(resourceName: "car.fill-1").withTintColor(UIColor.customColor(red: 2, green: 148, blue: 80), renderingMode: .alwaysOriginal)
            return view
        }
        return nil
    }
    
    //要畫出線條DrawingRender到地圖必須使用MapKit的Delegate Method
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let route = self.route {
            let polyline = route.polyline
            //要用MKPolylineRenderer來包裝一次路線 再使用線的物件去標明這條線
            let renderer = MKPolylineRenderer(overlay: polyline)
            renderer.strokeColor = UIColor.customColor(red: 10, green: 195, blue: 121)
            renderer.lineWidth = 4
            return renderer
        }
        //給予一個回傳物件
        return MKOverlayRenderer()
    }
}

//MARK: - Map Helper Functions
//只限於這個HomeController的extension
private extension HomeController {
    func searchBy(queryText: String, completion: @escaping([MKPlacemark]) -> Void ) {
        //1.地圖搜尋重要的變數 [MKPlacemark] -> 把地圖搜尋的位置裝在Array內
        //2.MKLocalsearch地圖搜尋物件
        var results = [MKPlacemark]()
        let request = MKLocalSearch.Request()
        //搜尋區域 = mapview的視途範圍
        request.region = mapView.region
        //搜尋文字設定
        request.naturalLanguageQuery = queryText
        //把request物件設定好的結果傳進MKLocalSearch內並construct為search
        let search = MKLocalSearch(request: request)
        //搜尋開始,接著把response內的地圖結果用forEach(設定參數為item)每個Placemark,append到result內
        search.start { (response, err) in
            if let err = err{
                print("DEBUG:Error causes \(err.localizedDescription)")
            }
            guard let response = response else {return}
            response.mapItems.forEach { item in
                //placemark有全部座標位置的相關資訊
                results.append(item.placemark)
            }
            completion (results)
        }
    }
    
    //MKMapItem的路線須為MKMapItem
    func generatePolyline(toDestination destination: MKMapItem) {
        //MKDircetion 根據提供的路線以計算路線的長度的物件,用request來提供(init)
        let request = MKDirections.Request()
        request.destination = destination
        //MKMapItem來使用裝置目前的位置 (用戶當前位置)
        request.source = MKMapItem.forCurrentLocation()
        //決定行進交通的方式(可選擇)
        request.transportType = .automobile
        //上面決定好request條件後 用MKDirections來物件化
        let directionRequest = MKDirections(request: request)
        directionRequest.calculate { (response, err) in
            if let err = err {
                print("DEBUG: can't get the direction requset \(err.localizedDescription)")
            }
            guard let response = response else { return }
            //將response於RouteArray內的第一條路線存回預先設定的變數
            self.route = response.routes[0]
            //接著再將route創建出polyline
            guard let polyline = self.route?.polyline else { return }
            //再用addOverlay加入線條(線條物件用overlay) 但注意,目前尚未render出來只是先規定好路線
            self.mapView.addOverlay(polyline)
        }
    }
    
    func removeAnnotationAndPolyline() {
        //remove 文字地圖產生出來的annotation
        mapView.annotations.forEach { (annotation) in
            if let anno = annotation as? MKPointAnnotation {
                mapView.removeAnnotation(anno)
            }
        }
        //overlay變數是和地圖相關連的項目,即當前array內只會有一條路線
        if mapView.overlays.count > 0 {
            mapView.removeOverlay(mapView.overlays[0])
        }
    }
    
    func centerMapOnUserLocation() {
        guard let coordinates = locationManager?.location?.coordinate else {return}
        mapView.setCenter(coordinates, animated: true)
    }
    
    func setCustomRegion(type:AnnotationType, coordintes: CLLocationCoordinate2D) {
        //使用LocationManager功能的座標相關功能來監測該範圍區域
        let region = CLCircularRegion(center: coordintes, radius: 8, identifier: type.rawValue)
        locationManager?.startMonitoring(for: region)
    }
    
    func zoomActiveTrip(withDriverUid uid: String) {
        //建立array將Driver的Anno透過uid的篩選後append進去做zoomIn
        var array = [MKAnnotation]()
        self.mapView.annotations.forEach { (annotations) in
            if let anno = annotations as? DriverAnnotation  {
                if anno.uid == uid{
                    array.append(anno)
                }
            }
            if let userAnno = annotations as? MKUserLocation {
                array.append(userAnno)
            }
        }
        self.mapView.zoomInMap(annotationsInRect: array)
    }
}

//MARK: - RideActionViewDelegate
extension HomeController: RideActionViewDelegate {
    func deleteTrip() {
        PassengerService.shared.deleteTrip { (err, ref) in
            if let err = err {
                print("DEBUG: Cancel Trip Failed \(err.localizedDescription)")
            }
            self.showRideActionView(shouldShow: false)
            self.removeAnnotationAndPolyline()
            self.configureActionButton(configState: .showMenu)
            self.centerMapOnUserLocation()
            UIView.animate(withDuration: 0.6) {
                self.inputActivationView.alpha = 1
            }
        }
    }
    
    func updateTripInfo(inputDestination: RideActionView) {
        //直接取得當前user位置的座標
        guard let pickupCoordinate = locationManager?.location?.coordinate else {return}
        guard let destination = inputDestination.destination?.coordinate else {return}
        ShouldPresentLoadingView(true, message: "請耐心等候，正在搜尋中...")
        PassengerService.shared.updateTrip(pickupCoordinate, destination) { (err, ref) in
            if let err = err {
                print("DEBUG:Failed to upload trip \(err.localizedDescription)")
                return
            }
            self.rideActionView.frame.origin.y = self.view.frame.height //消失rideActionView
        }
    }
    
    func startTripToDestination() {
        startTrip()
    }
    
    func dropOff() {
        guard let tripData = tripData else {return}
        DriverService.shared.updateTripState(trip: tripData, state: .completed) { (err, ref) in
            self.removeAnnotationAndPolyline()
            self.centerMapOnUserLocation()
            self.showRideActionView(shouldShow: false)
        }
    }
}

//MARK: - PickupControllerDelegate
extension HomeController: PickupControllerDelegate {
    func didAcceptTrip(tripDataUpdated: Trip) {
        guard let tripDataUpdated = tripData else { return}
        mapView.generateAnnotation(withCoordinates: tripDataUpdated.pickupCoordinate)
        setCustomRegion(type: .pickup, coordintes: tripDataUpdated.pickupCoordinate)
        //先init地圖資訊 -> 再用地圖資訊init地圖特殊物件功能
        let placemark = MKPlacemark(coordinate: tripDataUpdated.pickupCoordinate)
        let mapItem = MKMapItem(placemark: placemark)
        generatePolyline(toDestination: mapItem)
        //抓出畫面上剛剛創建的乘客的Anno跟目前地圖上有一個Driver的Anno,因此用Annotations代入
        mapView.zoomInMap(annotationsInRect: mapView.annotations)
        dismiss(animated: true) {
            Service.shared.fetchUserData(currentUid: tripDataUpdated.passengerUid) { (passenger) in
                self.showRideActionView(shouldShow: true, config: .tripAccepted, userData: passenger)
                self.observeCancelledTrip(trip: tripDataUpdated)
            }
        }
    }
}
