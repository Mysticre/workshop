//
//  AddLocationController.swift
//  UberClone
//
//  Created by Mysticre on 2022/3/1.
//

import UIKit
import MapKit

protocol AddLocationControllerDelegate: class {
    func addLocation(locationString: String, type: LocationType)
}

private let reuseIdentifier = "LocationCell"

class AddLocationController: UITableViewController {
    //MARK: - Properties
    weak var delegate:AddLocationControllerDelegate?
    private let location: CLLocation
    private let type: LocationType
    //searchBar的物件
    private let searchBar = UISearchBar()
    //執行位置表單搜尋需要該物件MKLocalSearch + MKLocalCompletion
    private let searchCompleter = MKLocalSearchCompleter()
    //將其didSet直接執行reloadData的動作
    private var searchResults = [MKLocalSearchCompletion]() {
        didSet {
            tableView.reloadData()
        }
    }
    
    //MARK: - LifeCycle
    //初始化一個帶有type和location的tableView物件
    init(type: LocationType, location: CLLocation) {
        self.type =  type
        self.location = location
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureTableView()
        configureSearchBar()
        configureSearchCompletion()
    }
    
    //MARK: - Helper Functions
    func configureTableView() {
        tableView.tableFooterView = UIView()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: reuseIdentifier)
        tableView.rowHeight = 60
        tableView.addShadow()
        tableView.backgroundColor = UIColor.customColor(red: 0, green: 93, blue: 68)
    }
    
    func configureSearchBar() {
        searchBar.delegate = self
        searchBar.sizeToFit() //貼合subView
        navigationItem.titleView = searchBar //將Navi的View用searchBar取代
    }
    
    func configureSearchCompletion() {
        let region = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: 2000, longitudinalMeters: 2000)
        searchCompleter.region = region
        searchCompleter.delegate = self
    }
}

//MARK: - UITableViewDelegate

extension AddLocationController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResults.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: reuseIdentifier)
        //將搜尋結果依照格子index順序填入
        let results = searchResults[indexPath.row]
        cell.backgroundColor = UIColor.customColor(red: 0, green: 93, blue: 68)
        cell.textLabel?.text = results.title
        cell.detailTextLabel?.text = results.subtitle
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let results = searchResults[indexPath.row]
        let location = results.title + " " + results.subtitle
        delegate?.addLocation(locationString: location, type: type)
    }
}

//MARK: - UISearchBarDelegate
extension AddLocationController: UISearchBarDelegate{
    //bar文字輸入變化就會產生文字結果並將文字丟到搜尋地圖內容內
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        searchCompleter.queryFragment = searchText
    }
}

//MARK: - MKLocalSearchCompleterDelegate
extension AddLocationController: MKLocalSearchCompleterDelegate {
    //搜尋結果更新時就存入searchResults內
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        searchResults = completer.results
    }
}
