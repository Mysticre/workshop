//
//  LoginController.swift
//  UberClone
//
//  Created by Mysticre on 2021/9/10.
//

import Foundation
import UIKit
import Firebase
import MapKit

class LoginViewController: UIViewController{
    // MARK: - Properties
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "TELEPORT"
        label.font = UIFont(name: "TESLA", size: 30)
        label.textColor = UIColor(white: 1, alpha: 0.87)
        return label
    }()
    
    private lazy var emailContainer: UIView = {
        let view = UIView().myContainerView(imagePic: #imageLiteral(resourceName: "ic_mail_outline_white_2x"), emailTField: emailTextField)
        //調整height以免stack被壓縮
        view.heightAnchor.constraint(equalToConstant: 50).isActive = true
        return view
    }()
    
    private let emailTextField: UITextField = {
        return UITextField().myTextField(placeHolder: "電子郵件")
    }()
    
    private lazy var passwordContainer: UIView = {
        let view = UIView().myContainerView(imagePic: #imageLiteral(resourceName: "ic_lock_outline_white_2x"), emailTField: passwordTextField)
        view.heightAnchor.constraint(equalToConstant:50).isActive = true
        return view
    }()
    
    private let passwordTextField: UITextField = {
        return UITextField().myTextField(placeHolder: "密碼" , isSecureTextEntry: true)
    }()
    
    
    private let loginButton: ButtonExtension = {
        let button = ButtonExtension(type: .system)
        button.setTitle("登入", for: .normal)
        button.addTarget(self, action: #selector(handleLogIn), for: .touchUpInside)
        return button
    }()
    
    private let registerButton: UIButton = {
        let button = UIButton(type: .system)
        //改變button的屬性(用NSMutableAttributedString來製造一個string才可以用append)
        var attributedTitle = NSMutableAttributedString(string: "您還沒有帳號嗎？", attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 16),    NSAttributedString.Key.foregroundColor : UIColor.lightGray])
        //用setAttributedTitle給button套用
        attributedTitle.append(NSAttributedString(string: " 請在這裡註冊", attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 16),NSAttributedString.Key.foregroundColor: UIColor.customColor(red: 2, green: 148, blue: 80)]))
        button.addTarget(self, action: #selector(handleSignUp), for: .touchUpInside)
        button.setAttributedTitle(attributedTitle , for: .normal)
        return button
    }()
    
    // MARK: - LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        configureNaviBar()
    }
    
    // MARK: - Selectors
    @objc func handleSignUp() {
        let controller = SignUpController()
        //畫面推送 要建立navigation controller的推送(push功能) + 到sceneDelegate把默認畫面改成navController
        navigationController?.pushViewController(controller, animated: true)
    }
    
    @objc func handleLogIn() {
        guard let email = emailTextField.text else {return}
        guard let password = passwordTextField.text else {return}
        Auth.auth().signIn(withEmail: email, password: password) { (result, err) in
            if let e = err {
                print("Fail to Login user info \(e.localizedDescription)")
                return
            } else {
                let keyWindow = UIApplication.shared.windows.first{$0.isKeyWindow}
                guard let controller = keyWindow?.rootViewController as? ContainerController else {return}
                controller.configureUI()
                self.dismiss(animated: true, completion: nil)
            }
        }
    }
    // MARK: - Helper Function
    
    func configureUI() {
        gradientBackgound(config: .background, background: self)
        
        view.addSubview(titleLabel)
        titleLabel.centerX(inView: view)
        titleLabel.anchor(top: view.safeAreaLayoutGuide.topAnchor, paddingTop: 12)
        
        let stack = UIStackView(arrangedSubviews: [emailContainer, passwordContainer, loginButton])
        stack.axis = .vertical
        stack.distribution = .fillEqually
        stack.spacing = 8
        
        //兩個加入stack的container畫面要加入height, 不然放到stack裡面會被壓縮
        view.addSubview(stack)
        stack.anchor(top: titleLabel.bottomAnchor, left: view.leftAnchor, right: view.rightAnchor, paddingTop: 40, paddingLeft: 8, paddingRight: 8)
        
        view.addSubview(loginButton)
        loginButton.anchor(top: stack.bottomAnchor, left: view.leftAnchor, right: view.rightAnchor, paddingTop: 40, paddingLeft: 8, paddingRight: 8)
        
        view.addSubview(registerButton)
        registerButton.anchor(bottom:view.safeAreaLayoutGuide.bottomAnchor, left: view.leftAnchor, right: view.rightAnchor, paddingBottom: 8, paddingLeft: 8, paddingRight: 8, height: 32)
    }
    
    func configureNaviBar() {
        navigationController?.isNavigationBarHidden = true
        navigationController?.navigationBar.barStyle = .black
    }
}

