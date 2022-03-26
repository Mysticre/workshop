//
//  MenuController.swift
//  UberClone
//
//  Created by Mysticre on 2022/2/26.
//

import UIKit
import Foundation

protocol MenuControllerDelegate: class {
    func didSelect(option: MenuOption)
}

enum MenuOption: Int, CaseIterable, CustomStringConvertible {
    case yourTrip
    case settings
    case logout
    
    var description: String{
        switch self {
        case .yourTrip: return "路線搜尋"
        case .settings: return "設置"
        case .logout: return "登出"
        }
    }
}
private let reuseIdentifier = "MenuCell"

class MenuController: UITableViewController {
    //MARK: - Properties
    private let userData: User
    weak var delegate: MenuControllerDelegate?
    
    private lazy var menuHeader: MenuHeader = {
        //定義好frame的大小再填入MenuHeader給予init
        let frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: 140)
        let view = MenuHeader(user: userData, frame: frame)
        return view
    }()
    
    //MARK: - LifeCycle
    //建造以外面的user帶入的客製化init 不同以didSet的用法直接用userObject給constructure起來
    init(user: User){
        self.userData = user
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureTableView()
    }
    
    //MARK: - Helper Functions
    func configureTableView() {
        tableView.backgroundColor = .white
        tableView.separatorStyle = .none
        tableView.isScrollEnabled = false
        tableView.rowHeight = 60
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: reuseIdentifier)
        tableView.tableHeaderView = menuHeader //客製化Header
        tableView.tableFooterView = UIView() //下半部的View用UIView取代
    }
}

extension MenuController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return MenuOption.allCases.count  //CaseIterable支援
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath)
        guard let options = MenuOption(rawValue: indexPath.row) else {return UITableViewCell()}
        cell.textLabel?.text = options.description
        cell.textLabel?.font = UIFont.systemFont(ofSize: 20)
        cell.backgroundColor = .white
        cell.textLabel?.textColor = .black
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let options = MenuOption(rawValue: indexPath.row) else {return}
        delegate?.didSelect(option: options)
    }
}


