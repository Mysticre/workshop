//
//  SignUpController.swift
//  UberClone
//
//  Created by Mysticre on 2021/9/24.
//

import UIKit
import Firebase
import GeoFire

class SignUpController: UIViewController {
    // MARK: - Properties
    private var location = LocationHandler.shared.locationManager.location
    
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
    
    private lazy var emailSignUpContainer: UIView = {
        let view = UIView().myContainerView(imagePic: #imageLiteral(resourceName: "ic_mail_outline_white_2x"), emailTField: emailTextField)
        view.heightAnchor.constraint(equalToConstant: 50).isActive = true
        return view
    }()
    
    private let emailTextField: UITextField = {
        return UITextField().myTextField(placeHolder: "請輸入電子郵件")
    }()
    
    private lazy var fullnameContainer: UIView = {
        let view = UIView().myContainerView(imagePic: #imageLiteral(resourceName: "ic_person_outline_white_2x"), emailTField: fullnameTextField)
        view.heightAnchor.constraint(equalToConstant: 50).isActive = true
        return view
    }()
    
    private let fullnameTextField: UITextField = {
        return UITextField().myTextField(placeHolder: "請輸入姓名")
    }()
    
    private lazy var passwordContainer: UIView = {
        let view=UIView().myContainerView(imagePic: #imageLiteral(resourceName: "ic_lock_outline_white_2x"), emailTField: passwordTextField)
        view.heightAnchor.constraint(equalToConstant: 50).isActive = true
        return view
    }()
    
    private let passwordTextField: UITextField = {
        return UITextField().myTextField(placeHolder: "請輸入密碼 ", isSecureTextEntry: true)
    }()
    
    private lazy var registerContainer: UIView = {
        let view = UIView().myContainerView(imagePic: #imageLiteral(resourceName: "ic_account_box_white_2x"), segControl: registerControl)
        view.heightAnchor.constraint(equalToConstant: 65).isActive = true
        return view
    }()
    //分離式選單UISegmentedControl
    private let registerControl: UISegmentedControl = {
        let sc = UISegmentedControl(items: ["司機", "乘客"])
        sc.backgroundColor = .systemGray
        sc.tintColor = .systemBackground
        sc.selectedSegmentIndex = 0
        return sc
    }()
    
    private let signupButton: ButtonExtension = {
        let button = ButtonExtension(type: .system)
        button.setTitle("註冊", for: .normal)
        button.addTarget(self, action: #selector(handleForSighUp), for: .touchUpInside)
        return button
    }()
    
    private let hadAccountLogIn: UIButton = {
        let button = UIButton()
        var attributeWord = NSMutableAttributedString(string: "您已經擁有帳號了嗎？ ", attributes:[NSAttributedString.Key.font : UIFont.systemFont(ofSize: 16), NSAttributedString.Key.foregroundColor : UIColor.systemGray])
        
        attributeWord.append(NSMutableAttributedString(string: " 請由此登入", attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 16), NSMutableAttributedString.Key.foregroundColor : UIColor.customColor(red: 2, green: 148, blue: 80) ]))
        
        button.setAttributedTitle(attributeWord, for: .normal)
        button.addTarget(self, action: #selector(backToLogInController), for: .touchUpInside)
        return button
    }()
    
    // MARK: - LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
    }
    
    // MARK: - Selector
    @objc func backToLogInController() {
        //pop回到顯示上一層的ViewController
        navigationController?.popViewController(animated: true)
    }
    
    @objc func handleForSighUp() {
        //資料庫連結完成後 紀錄資料庫資料內容將要記錄的內容用變數儲存
        guard let email = emailTextField.text else {return}
        guard let password = passwordTextField.text else {return}
        guard let fullname = fullnameTextField.text else {return}
        //因為還不確定數字為0或是1所以用不用guard let
        let accountType = registerControl.selectedSegmentIndex
        
        //資料庫創建user的code
        Auth.auth().createUser(withEmail: email, password: password) { (result, err) in
            if let e = err{
                print("Failed to create user, \(e)")
                return
            }
            //用result的結果呼叫出uid
            guard let uid = result?.user.uid else {return}
            //因為有accountType所以整個dic需轉為key-value為    [string:Any]
            let values = ["email":email, "fullname":fullname, "accountType":accountType] as [String:Any]
            
            if accountType == 0 {
                let geo = GeoFire(firebaseRef:REF_DRIVER_LOCATIONS)
                if let location = self.location {
                    geo.setLocation(location, forKey: uid) { (err) in
                        if let e = err {
                            print("DEBUG: \(e.localizedDescription)");
                        }else{
                            self.updateUserChildValues(uid: uid, values: values)
                        }
                    }
                }
            }
            self.updateUserChildValues(uid: uid, values: values)
        }
    }
    
    // MARK: - Helper Functions
    func updateUserChildValues(uid: String, values: [String:Any]) {
        //寫入資料庫資料時的語法 配合key和string與新增上傳該child與node資料
        DB_REF.child("users").child(uid).updateChildValues(values) { (err, ref) in
            if let e = err {
                print("failed to update data \(e)")
            } else{
                let window = UIApplication.shared.windows.first{$0.isKeyWindow}
                guard let controller = window?.rootViewController as? ContainerController else {return}
                controller.configureUI()
                print("update user data successfully")
                self.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    func configureUI() {
        gradientBackgound(config: .background, background: self)
        
        view.addSubview(titleLabel)
        titleLabel.centerX(inView: view)
        titleLabel.anchor(top: view.safeAreaLayoutGuide.topAnchor, paddingTop: 12)
        
        let stack = UIStackView(arrangedSubviews: [emailSignUpContainer, fullnameContainer, passwordContainer, registerContainer])
        stack.axis = .vertical
        stack.distribution = .fillProportionally
        stack.spacing = 16
        
        view.addSubview(stack)
        stack.anchor(top:titleLabel.bottomAnchor, left: view.leftAnchor, right: view.rightAnchor, paddingTop: 8, paddingLeft: 8, paddingRight: 8)
        
        view.addSubview(signupButton)
        signupButton.anchor(top:stack.bottomAnchor, left: view.leftAnchor, right: view.rightAnchor, paddingTop: 100, paddingLeft: 8, paddingRight: 8)
        
        view.addSubview(hadAccountLogIn)
        hadAccountLogIn.anchor(bottom: view.safeAreaLayoutGuide.bottomAnchor)
        hadAccountLogIn.centerX(inView: view)
    }
}
