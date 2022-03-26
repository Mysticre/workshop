//
//  UserInfoHeader.swift
//  UberClone
//
//  Created by Mysticre on 2022/3/1.
//

import UIKit

class UserInfoHeader: UIView {
    //MARK: - Properties
    private let userData: User

    private lazy var  profileImageView: UIView = {
        let imageView = UIView()
        imageView.backgroundColor = UIColor.customColor(red: 0, green: 93, blue: 68)
        imageView.addSubview(profileLabel)
        profileLabel.centerX(inView: imageView)
        profileLabel.centerY(inView: imageView)
        return imageView
    }()
    
    private lazy var profileLabel: UILabel = {
        let label = UILabel()
        label.text = String(userData.fullname.prefix(1))
        label.font = UIFont(name: "TESLA", size: 30)
        label.textColor = .white
        return label
    }()
    
    private lazy var fullnameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 20)
        label.textColor = .black
        label.text = userData.fullname
        return label
    }()
    
    private lazy var emailLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 18)
        label.textColor = .lightGray
        label.text = userData.email
        return label
    }()
    
    
    //MARK: - LifeCycle
    //直接創造帶有object的 frame
    init(user:User, frame:CGRect) {
        self.userData = user
        super.init(frame: frame)
        configureUIView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: - Helper Functions
    
    func configureUIView () {
        backgroundColor = .white
        
        addSubview(profileImageView)
        profileImageView.anchor(top: self.topAnchor, left: self.leftAnchor, paddingTop: 18, paddingLeft: 12)
        profileImageView.setDimensions(height: 64, width: 64)
        profileImageView.layer.cornerRadius = 64 / 2
        
        let stack = UIStackView(arrangedSubviews: [fullnameLabel, emailLabel])
        stack.axis = .vertical
        stack.distribution = .fillEqually
        stack.spacing = 4
        
        addSubview(stack)
        stack.centerY(inView: self)
        stack.anchor(left:profileImageView.rightAnchor, paddingLeft: 18)
    }
}
