//
//  ContainerController.swift
//  UberClone
//
//  Created by Mysticre on 2022/2/26.
//

//用ContainerView包住HomeController和MenuController來展示底層與表層畫面的切換

import UIKit
import Foundation
import Firebase

class ContainerController: UIViewController {
    //MARK: - Properties
    private let homeController = HomeController()
    private var menuController: MenuController!
    private let launchView = LaunchView()
    private var isExpanded: Bool = false
    private let blackView = UIView()
    private lazy var xOrigin = self.view.frame.width - 80 //x軸開始的地方 是從寬度減掉(從後面算)80的地方
    private var userData: User? {
        didSet{
            guard let userData = userData else {return}
            homeController.userData = userData
            configureMenuController(withUser: userData)
        }
    }
    
    override var prefersStatusBarHidden: Bool {
        return isExpanded
    }
    
    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation{
        return .slide
    }
    
    //MARK: - LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        configureLaunchScreen()
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.checkIfUserLogin()
        }
    }
    
    //MARK: - API
    func checkIfUserLogin() {
        if Auth.auth().currentUser?.uid == nil {
            presentControllerWithVersionCheckin()
        }else{
            configureUI()
            print("Current User's uid is \(String(describing: Auth.auth().currentUser?.uid))")
        }
    }
    
    func fetchUserData() {
        guard let currentUid = Auth.auth().currentUser?.uid else {return}
        Service.shared.fetchUserData(currentUid: currentUid) { (user) in
            self.userData = user
        }
    }
    
    func signOut() {
        do{
            try Auth.auth().signOut()
            presentControllerWithVersionCheckin()
        } catch {
            print("DEBUG: Error sign out ")
        }
    }
    
    //MARK: - Helper Functions
    func presentControllerWithVersionCheckin() {
        DispatchQueue.main.async {
            let nav = UINavigationController(rootViewController:LoginViewController())
            if #available(iOS 13.0 , *) {
                nav.isModalInPresentation = true
            }
            nav.modalPresentationStyle = .fullScreen
            self.present(nav, animated: true, completion: nil)
        }
    }
    
    func configureUI() {
        view.backgroundColor = UIColor.customColor(red: 0, green: 93, blue: 68)
        fetchUserData()
        configureHomeController()
    }
    
    func configureLaunchScreen() {
        addChild(launchView)
        launchView.didMove(toParent: self)
        view.insertSubview(launchView.view, at: 3)
    }
    
    //插入HomeController頁面到ContainerController裡面
    func configureHomeController() {
        //用addChild把controller加入在其中
        addChild(homeController)
        homeController.didMove(toParent: self)
        view.insertSubview(homeController.view, at: 2)
        homeController.delegate = self
    }
    
    func configureMenuController(withUser user: User) {
        menuController = MenuController(user: user)
        addChild(menuController)
        menuController.didMove(toParent: self)
        //重要! 因為UIkit的位置預設為0,0,0,0 所以要調整位置
        menuController.view.frame = CGRect(x: 0, y:50 , width: self.view.frame.width, height: self.view.frame.height - 50)
        view.insertSubview(menuController.view, at: 1)
        menuController.delegate = self
        configureBlackView()
    }
    
    func showMenu(shouldShow: Bool, completion: ((Bool) -> Void)? = nil) {
        if shouldShow {
            UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .curveEaseInOut, animations: {
                self.homeController.view.frame.origin.x = self.xOrigin
                self.blackView.alpha = 1
                self.blackView.frame = CGRect(x: self.xOrigin, y: 0, width: 80, height: self.view.frame.height)
            }, completion: completion)
        }else{
            UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .curveEaseInOut, animations: {
                self.homeController.view.frame.origin.x = 0
                self.blackView.alpha = 0
            }, completion: completion)
        }
        animateStatusBar()
    }
    
    func configureBlackView() {
        blackView.frame = self.view.bounds //frame 是根據superview的座標位置 bounds是該圖自己的位置
        blackView.backgroundColor = UIColor(white: 0, alpha: 0.5)
        blackView.alpha = 0
        view.addSubview(blackView)
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissMenu))
        blackView.addGestureRecognizer(tap)
    }
    
    func animateStatusBar() {
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .curveEaseInOut, animations: {
            self.setNeedsStatusBarAppearanceUpdate() //可以讓status bar出現時有動畫產生
        }, completion: nil)
    }
    
    //MARK: - Selectors
    @objc func dismissMenu() {
        isExpanded = false
        showMenu(shouldShow: isExpanded)
    }
}

//MARK: - HomeControllerDelegate
extension ContainerController: HomeControllerDelegate{
    func handleMenuToggle() {
        isExpanded.toggle()
        showMenu(shouldShow: isExpanded)
    }
}

//MARK: - MenuControllerDelegate
extension ContainerController: MenuControllerDelegate{
    func didSelect(option: MenuOption) {
        isExpanded.toggle()
        showMenu(shouldShow: isExpanded) { _  in
            switch option {
            case .yourTrip:
                break
            case .settings:
                guard let userData = self.userData else {return}
                let controller = SettingsController(userData: userData)
                controller.delegate = self
                let nav = UINavigationController(rootViewController: controller)
                self.present(nav, animated: true, completion: nil)
            case .logout: //加入兩個alert動作 + present動作
                let alert = UIAlertController(title: nil, message: "您確認要登出嗎？", preferredStyle: .actionSheet)
                alert.addAction(UIAlertAction(title: "登出", style: .destructive, handler: { _ in
                    self.signOut() //handler->執行這個動作
                }))
                alert.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
}

extension ContainerController: SettingControllerDelegate {
    func updateUserObjectFromSettings(_ controller: SettingsController) {
        self.userData = controller.userData
    }
}
