//
//  SettingsControleer.swift
//  UberClone
//
//  Created by Mysticre on 2022/2/28.
//

import UIKit
import CoreLocation
import MapKit

protocol SettingControllerDelegate: class {
    func updateUserObjectFromSettings ( _ controller: SettingsController)
}

enum LocationType: Int, CaseIterable, CustomStringConvertible {
    case home
    case work
    
    var description: String {
        switch self {
        case .home: return "居住地點"
        case .work: return "工作地點"
        }
    }
    
    var subTitle: String {
        switch self {
        case .home: return "新增居住地點"
        case .work: return "新增工作地點"
        }
    }
}

private let reuseIdentifier = "Location Cell"

class SettingsController: UITableViewController {
    //MARK: - Properties
    weak var delegate: SettingControllerDelegate?
    var userData: User
    var userInfoUpdated = false
    private let mapView = MKMapView()
    private let locationManager = LocationHandler.shared.locationManager
    
    private lazy var infoHeader: UserInfoHeader = {
        let frame = CGRect(x: 0, y: 80, width: view.frame.width, height: 100)
        let view = UserInfoHeader(user: userData, frame: frame)
        return view
    }()
    
    //MARK: - LifeCycle
    init(userData: User){
        self.userData = userData
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureNavBar()
        configureTableView()
    }
    
    //MARK: - Helper Functions
    func configureTableView() {
        tableView.rowHeight = 60
        tableView.register(LocationInputCell.self, forCellReuseIdentifier: reuseIdentifier)
        tableView.backgroundColor = .white
        tableView.tableHeaderView = infoHeader
    }
    
    func configureNavBar() {
        //bar跟item為調整項
        navigationItem.title = "設置"
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationController?.navigationBar.isTranslucent = true
        navigationController?.navigationBar.backgroundColor = UIColor.customColor(red: 0, green: 93, blue: 68)
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "baseline_clear_white_36pt_2x").withRenderingMode(.alwaysOriginal), style: .plain, target: self, action: #selector(handleDismissal))
    }
    
    func locationTextUpdate(forType type: LocationType) -> String{
        switch type{
        case .home:
            return userData.home ?? type.subTitle
        case .work:
            return userData.work ?? type.subTitle
        }
    }
    
    //MARK: - Selectors
    @objc func handleDismissal() {
        if userInfoUpdated{
            delegate?.updateUserObjectFromSettings(self)
        }
        self.dismiss(animated: true , completion: nil)
    }
}

extension SettingsController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return LocationType.allCases.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath) as! LocationInputCell
        cell.backgroundColor = .white
        guard let locationType = LocationType(rawValue: indexPath.row) else {return cell}
        cell.titleLabel.text = locationType.description
        cell.titleLabel.textColor = .black
        cell.subTitle.text = locationTextUpdate(forType: locationType)
        cell.subTitle.textColor = .black
        return cell
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView()
        view.backgroundColor = UIColor.customColor(red: 0, green: 93, blue: 68)
        
        let label = UILabel()
        label.text = "已儲存的地點"
        label.font = UIFont.systemFont(ofSize: 18)
        label.textColor = .white
        
        view.addSubview(label)
        label.centerY(inView: view)
        label.anchor(left: view.leftAnchor, paddingLeft: 12)
        return view
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let locationType = LocationType(rawValue: indexPath.row) else{return}
        guard let location = locationManager?.location else {return}
        let controller = AddLocationController(type: locationType, location: location)
        controller.delegate = self
        let nav = UINavigationController(rootViewController: controller)
        present(nav, animated: true, completion: nil)
    }
}

extension SettingsController: AddLocationControllerDelegate {
    func addLocation(locationString: String, type: LocationType) {
        PassengerService.shared.saveLocation(locationString: locationString, type: type) { (err, ref) in
            self.userInfoUpdated = true
            self.dismiss(animated: true) {
                self.mapView.setUserTrackingMode(.follow, animated: true)
            }
            //更新userData物件(只存取該次更新Setting的user結果,app並無永久儲存)
            switch type {
            case . home:
                self.userData.home = locationString
            case .work:
                self.userData.work = locationString
            }
            self.tableView.reloadData()
        }
    }
}

