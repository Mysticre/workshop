//
//  LocationInputCell.swift
//  UberClone
//
//  Created by Mysticre on 2021/12/22.
//

import UIKit
import MapKit

class LocationInputCell: UITableViewCell {
//MARK: - Properties
    //MKPlacemark要加optional可以不參與init
    var placemarks: MKPlacemark? {
        didSet{
            titleLabel.text = placemarks?.name
            subTitle.text = placemarks?.title
        }
    }
    
    var titleLabel:UILabel = {
        let label = UILabel()
        label.textColor = .black
        label.font = UIFont.systemFont(ofSize: 18)
        return label
    }()
    
    var subTitle: UILabel = {
        let label = UILabel()
        label.textColor = .gray
        label.font = UIFont.systemFont(ofSize: 14)
        return label
    }()
    
//MARK: - LifeCycle
    //創造cell的init(會根據不同的class有不同的init)
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style:style, reuseIdentifier: reuseIdentifier)
        //cell點選取消出現灰階效果
        selectionStyle = .none
        //以stack整理
        let stack = UIStackView(arrangedSubviews: [titleLabel , subTitle])
        stack.axis = .vertical
        stack.distribution = .fillEqually
        stack.spacing = 4
        
        addSubview(stack)
        stack.centerY(inView: self)
        stack.anchor(left:self.leftAnchor , paddingLeft: 16)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
