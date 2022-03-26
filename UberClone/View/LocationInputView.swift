//
//  LocationInputView.swift
//  UberClone
//
//  Created by Mysticre on 2021/12/14.
//

import UIKit

protocol LocationInputViewDelegate: class {
    func dismissLocationInputView ()
    func executeSearch(text: String)
}

class LocationInputView: UIView {
//MARK: - Properties
    var inputTitleLabel: User? {
        didSet {
            nameLabel.text = inputTitleLabel?.fullname
        }
    }
    weak var delegate: LocationInputViewDelegate?
    
    private let backButton: UIButton = {
        let button = UIButton(type: .system)
        //rendering mode改變按鈕顏色(非預設顏色)
        button.setImage(#imageLiteral(resourceName: "baseline_arrow_back_black_36dp").withTintColor(.white, renderingMode: .alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(handleBackTapped), for: .touchUpInside)
        return button
    }()
    
    private let startLocationPoint: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGray
        return view
    }()
    
    private let linkinView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGray
        return view
    }()
    
    private let endLocationPoint: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        return view
    }()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 16)
        return label
    }()
    
    private let startingLocationTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "目前所在位置"
        tf.textColor = .darkGray
        tf.font = UIFont.systemFont(ofSize: 16)
        tf.backgroundColor = .lightGray
        //鎖定輸入字元的指令
        tf.isEnabled = false
        return tf
    }()
    
    //lazy var (for delegate)
    private lazy var destinationLocationTextField: UITextField = {
        let tf = UITextField()
        tf.delegate = self
        tf.font = UIFont.systemFont(ofSize: 18)
        tf.attributedPlaceholder = NSAttributedString(string: "請輸入位置", attributes: [NSAttributedString.Key.foregroundColor : UIColor.darkGray])
        tf.textColor = .darkGray
        tf.backgroundColor = .white
//鍵盤按下enter的字樣
        tf.returnKeyType = .search
        return tf
    }()
    
    //MARK: - LifeCycle
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.customColor(red: 0, green: 93, blue: 68)
        
        addSubview(backButton)
        backButton.setDimensions(height: 25, width: 25)
        backButton.anchor(top:self.topAnchor, left:self.leftAnchor, paddingTop:40 , paddingLeft:8)
        
        addSubview(startLocationPoint)
        startLocationPoint.setDimensions(height: 4, width: 4)
        startLocationPoint.anchor(top:backButton.bottomAnchor, left: self.leftAnchor, paddingTop:24, paddingLeft: 32 )
        
        addSubview(linkinView)
        linkinView.setDimensions(height: 48, width: 2)
        linkinView.anchor(top:startLocationPoint.bottomAnchor, left:self.leftAnchor, paddingTop: 8, paddingLeft: 33)
        
        addSubview(endLocationPoint)
        endLocationPoint.setDimensions(height: 4, width: 4)
        endLocationPoint.anchor(top:linkinView.bottomAnchor, left: self.leftAnchor, paddingTop: 8, paddingLeft: 32)

        addSubview(nameLabel)
        nameLabel.centerX(inView: self)
        nameLabel.centerY(inView: backButton)
        nameLabel.setDimensions(height: 25, width: 100)

        addSubview(startingLocationTextField)
        startingLocationTextField.anchor(top:nameLabel.bottomAnchor, left: startLocationPoint.rightAnchor, right: self.rightAnchor, paddingTop: 16, paddingLeft: 8, paddingRight: 48)
        startingLocationTextField.setDimensions(height: 30, width: 24)
        
        addSubview(destinationLocationTextField)
        destinationLocationTextField.anchor(top:startingLocationTextField.bottomAnchor, left: endLocationPoint.rightAnchor, right: self.rightAnchor, paddingTop:32, paddingLeft: 8, paddingRight: 48)
        destinationLocationTextField.setDimensions(height: 30, width: 24)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: - Selectors
    @objc func handleBackTapped() {
        delegate?.dismissLocationInputView()
    }
}

//MARK: - UITextFieldDelegate
//每當搜尋鍵按下時是否都會執行客製化的行爲
extension LocationInputView: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        guard let queryText = textField.text else {return false}
        delegate?.executeSearch(text: queryText)
        return true
    }
}
