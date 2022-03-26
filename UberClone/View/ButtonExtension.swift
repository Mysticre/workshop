//
//  ButtonExtension.swift
//  UberClone
//
//  Created by Mysticre on 2021/10/4.
//

import UIKit

class ButtonExtension: UIButton {
    override init(frame: CGRect) {
        super.init(frame: frame)
        setTitleColor(UIColor(white: 1, alpha: 0.87), for: .normal)
        backgroundColor = UIColor.customColor(red: 0, green: 128, blue: 128)
        layer.cornerRadius = 6
        //記得要對物件有個高度的限制和active
        heightAnchor.constraint(equalToConstant: 50).isActive = true
        titleLabel?.font = UIFont.systemFont(ofSize: 24)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
