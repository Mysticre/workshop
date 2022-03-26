//
//  PickupController.swift
//  UberClone
//
//  Created by Mysticre on 2022/2/6.
//

import Foundation
import UIKit
import MapKit

//更新過後的Trip在Passenger方沒有呼叫ObserveTrip的Function, 因此Passenger方沒有最新的ObserveTrip的資料,所以使用Delegate的方式到HomeController執行更新TripObject的資料
//Controller將等待Trip Observe完畢後, 在HomeController用didSet的方式present上來
//所以需要用Trip的Object來init該Controller

protocol PickupControllerDelegate: class {
    //建立參數給予Controller傳遞資料
    func didAcceptTrip(tripDataUpdated: Trip)
}

class PickupController: UIViewController {
    //MARK: - Properties
    weak var delegate: PickupControllerDelegate?
    var tripData: Trip
    private let mapView = MKMapView()
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    private lazy var circularView: CircularProgressView = {
        let frame = CGRect(x: 0, y: 0, width: 360, height: 360)
        let circular = CircularProgressView(frame: frame)
        //把mapView疊加到circular上面去
        circular.addSubview(mapView)
        mapView.setDimensions(height: 268, width: 268)
        mapView.layer.cornerRadius = 268 / 2
        mapView.centerX(inView: circular)
        mapView.centerY(inView: circular, constant: 32)
        return circular
    }()
    
    private let cancelButton: UIButton = {
        let button = UIButton()
        button.setImage(#imageLiteral(resourceName: "baseline_clear_white_36pt_2x").withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(handleDismiss), for: .touchUpInside)
        return button
    }()
    
    private let pickupLabel: UILabel = {
        let label = UILabel()
        label.text = "您要接受此趟任務嗎？"
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 20)
        label.textColor = .white
        return label
    }()
    
    private let acceptButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = .white
        button.titleLabel?.font = UIFont.systemFont(ofSize: 20)
        button.setTitleColor(.black, for: .normal)
        button.setTitle("接受乘載", for: .normal)
        button.addTarget(self, action: #selector(handleAcceptTrip), for: .touchUpInside)
        return button
    }()
    
    //MARK: - LifeCycle
    //帶有Trip物件格式的PickupController
    init(trip: Trip) {
        self.tripData = trip
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        configureMapViewUI()
        //展示動畫的指令要用selector表現啟動的動畫
        perform(#selector(animateProgress), with: nil, afterDelay: 0.1)
    }
    
    //MARK: - Selectors
    @objc func handleDismiss() {
        DriverService.shared.updateTripState(trip: self.tripData, state: .denied) { (err, ref) in
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    @objc func handleAcceptTrip() {
        //從HomeController來的Trip丟入function內
        DriverService.shared.acceptTrip(trip: tripData) { (err, ref) in
            self.delegate?.didAcceptTrip(tripDataUpdated: self.tripData) //丟要運行的內容到裡面
        }
    }
    
    @objc func animateProgress() { //啟動動畫的objc func
        circularView.animatePulsatingLayer()
        circularView.setProgressWithAnimation(duration: 20, value: 0) {//這個completion象徵動畫結束後的行為
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    //MARK: - Helper Functions
    func configureUI() {
        view.backgroundColor = .black
        
        view.addSubview(cancelButton)
        cancelButton.anchor(top: view.safeAreaLayoutGuide.topAnchor, left: view.leftAnchor, paddingLeft: 16)
        cancelButton.setDimensions(height: 32, width: 32)
        
        view.addSubview(circularView)
        circularView.setDimensions(height: 360, width: 360)
        circularView.anchor(top:view.safeAreaLayoutGuide.topAnchor, paddingTop: 32)
        circularView.centerX(inView: view)
        
        view.addSubview(pickupLabel)
        pickupLabel.centerX(inView: view)
        pickupLabel.anchor(top: mapView.bottomAnchor, paddingTop: 16)
        
        view.addSubview(acceptButton)
        acceptButton.anchor(top:pickupLabel.bottomAnchor, left: view.leftAnchor, right: view.rightAnchor,
                            paddingTop: 16, paddingLeft: 32, paddingRight: 32)
        acceptButton.setDimensions(height: 50, width: 0)
    }
    
    func configureMapViewUI() {  //調整畫面的mapview到指定的區域
        let region = MKCoordinateRegion(center: tripData.pickupCoordinate , latitudinalMeters: 1000, longitudinalMeters: 1000)
        //用setRegion設置座標位置
        mapView.setRegion(region, animated: true)
        mapView.generateAnnotation(withCoordinates: tripData.pickupCoordinate)
    }
}
