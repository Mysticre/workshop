//
//  RideActionView.swift
//  UberClone
//
//  Created by Mysticre on 2022/1/25.
//

import UIKit
import MapKit

protocol RideActionViewDelegate: class {
    func updateTripInfo(inputDestination: RideActionView)
    func deleteTrip ()
    func startTripToDestination()
    func dropOff()
}

enum RideActionViewConfuguration {
    case requestRide
    case tripAccepted
    case driverArrived
    case pickupPassenger
    case tripInProgress
    case endTrip

    init() {
        self = .requestRide
    }
}

//使用CustomStringConvertible 設定不同的文字變化
enum ButtonAction: CustomStringConvertible {
    case requestRide
    case cancel
    case getDirection
    case inProgress
    case pickup
    case dropOff
    
    var description: String {
        switch self {
        case .requestRide:
            return "開始搜尋"
        case .cancel:
            return "取消"
        case .getDirection:
            return "已取得乘客位置路線"
        case .inProgress:
            return"正在前往目的地中..."
        case .pickup:
            return "請確認已乘接乘客"
        case .dropOff:
            return "乘客下車"
        }
    }
    
    init(){
        self = .requestRide
    }
}

class RideActionView: UIView{
    //MARK: - Properties
    weak var delegate: RideActionViewDelegate?
    var configRideAction = RideActionViewConfuguration()
    var buttonState = ButtonAction()
    var userData: User?
    var t:Double = 0
    weak var timer: Timer?
    var destination: MKPlacemark? {
        didSet {
            titleLabel.text = destination?.name
            subTitle.text = destination?.title
        }
    }
    var labelArray = ["感謝您選擇Teleport成為您的旅途夥伴😘",
                      "您知道嗎，在非洲每60秒就有1分鐘過去😬",
                      "滴滴打車？那是什麼🤔",
                      "不論是司機還是乘客都要友好相處哦🥰",
                      "上面的只是裝飾, 搜尋司機請按下面的按鈕👇"]

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .black
        label.font = UIFont.systemFont(ofSize: 20)
        label.textAlignment = .center
        return label
    }()
    
    private let subTitle: UILabel = {
        let label = UILabel()
        label.textColor = .systemGray
        label.font = UIFont.systemFont(ofSize: 18)
        label.textAlignment = .center
        return label
    }()
    
    private lazy var view: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.customColor(red: 0, green: 93, blue: 68)
        //使用lazy var直接嵌入文字合併進View
        view.addSubview(userLabel)
        userLabel.centerX(inView: view)
        userLabel.centerY(inView: view)
        return view
    }()
    
    private let userLabel: UILabel = {
        let label = UILabel()
        label.text = "TP"
        label.font = UIFont(name: "TESLA", size: 20)
        label.textColor = .white
        return label
    }()
    
    private lazy var bottomLabel: UILabel = {
        let label = UILabel()
        timer = Timer.scheduledTimer(withTimeInterval: 5 + t, repeats: true) {timer in
            label.text = self.labelArray.randomElement()
            self.t += 0.5
            while self.t == 16{
                timer.invalidate()
                break
            }
        }
        label.textColor = .lightGray
        label.font = UIFont.systemFont(ofSize: 14)
        label.textAlignment = .center
        return label
    }()
    
    private let segLine: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGray
        return view
    }()

    private let button: UIButton = {
        let button = UIButton()
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 20)
        button.addTarget(self, action: #selector(confirmUber), for: .touchUpInside)
        button.backgroundColor = UIColor.customColor(red: 0, green: 93, blue: 68)
        return button
    }()
    
    //MARK: - LifeCycle
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .white
        let stackView = UIStackView(arrangedSubviews: [titleLabel, subTitle])
        stackView.axis = .vertical
        stackView.distribution = .fillEqually
        stackView.spacing = 4
        
        addSubview(stackView)
        stackView.centerX(inView: self)
        stackView.anchor(top: self.topAnchor, paddingTop: 20)
        
        addSubview(view)
        view.centerX(inView: self)
        view.anchor(top: stackView.bottomAnchor, paddingTop: 12)
        view.setDimensions(height: 60, width: 60)
        view.layer.cornerRadius = 30
        
        addSubview(bottomLabel)
        bottomLabel.centerX(inView: self)
        bottomLabel.anchor(top:view.bottomAnchor, paddingTop: 12)
        
        addSubview(segLine)
        segLine.anchor(top:bottomLabel.bottomAnchor, left:self.leftAnchor, right: self.rightAnchor, paddingTop: 8, paddingLeft:12, paddingRight: 12 )
        segLine.setDimensions(height: 2, width: 2)
        
        addSubview(button)
        button.anchor(bottom: self.safeAreaLayoutGuide.bottomAnchor, left: self.leftAnchor, right: self.rightAnchor, paddingBottom: 24, paddingLeft: 12, paddingRight: 12)
        button.setDimensions(height: 40, width: 0)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: - Selectors
    @objc func confirmUber() {
        //用switch搭配切換多種按鍵功能
        //因為enum init預設為requestTrip,所以將updataTrip delegate加入第一個requestRide
        switch buttonState {
        case .requestRide:
            delegate?.updateTripInfo(inputDestination: self)
        case .cancel:
            delegate?.deleteTrip()
            configRideAction = .requestRide
        case .getDirection:
            break
        case .inProgress:
            break
        case .pickup:
            delegate?.startTripToDestination()
        case .dropOff:
            delegate?.dropOff()
        }
    }
    
    //MARK: - Helper Functions
    //建立function將enum搭配switch操作
    func configureUI(withConfig config: RideActionViewConfuguration){
        switch config{
        case .requestRide:
            buttonState = .requestRide
            button.setTitle(buttonState.description, for: .normal)
        case .tripAccepted:
            guard let userData = userData else {return}
            //因Driver方accept按鍵觸發帶出的user是passenger data所以畫面會顯示else的部分在ride action view
            if userData.accountType == .driver{      //由passenger呼叫帶出的資料
                titleLabel.text = "司機正在前往所在位置中..."
                buttonState = .cancel
                button.setTitle(buttonState.description, for: .normal)
            }else{
                titleLabel.text = "正在前往乘客位置中..."
                buttonState = .getDirection
                button.setTitle(buttonState.description, for: .normal)
                }
            userLabel.text = String(userData.fullname.first ?? "N")
            bottomLabel.text = userData.fullname
        case .driverArrived:
            guard let userData = userData else {return}
            if userData.accountType == .driver {
                titleLabel.text = "司機已抵達"
                subTitle.text = "請至搭乘地點等候司機..."
            }
        case .pickupPassenger: //only for Driver
            titleLabel.text = "抵達乘客所在位置"
            buttonState = .pickup
            button.setTitle(buttonState.description, for: .normal)
        case .tripInProgress:
            guard let userData = userData else {return}
            if userData.accountType == .driver{
                button.setTitle("前往指定位置中", for: .normal)
                subTitle.text = "正在前往中請稍候..."
            }else {
                buttonState = .inProgress
                button.setTitle(buttonState.description, for: .normal)
            }
            titleLabel.text = "正在前往目的地中"
        case .endTrip:
            guard let userData = userData else {return}
            if userData.accountType == .driver {
                button.setTitle("已到達目的地", for: .normal)
                buttonState = .requestRide
            }else {
                buttonState = .dropOff
                button.setTitle(buttonState.description, for: .normal)
                titleLabel.text = "已抵達目的地"
            }
        }
    }
}

