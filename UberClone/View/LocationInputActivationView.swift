//
//  LocationInputActivationView.swift
//  UberClone
//
//  Created by Mysticre on 2021/12/8.
//

import UIKit

//為了要讓HomeController可以代理InputView執行顯示功能(跨class執行功能) 創建使用Delegate Method
protocol LocationInputActivationViewDelegate: class {
    func presentLocationInputView()
}

class LocationInputActivationView: UIView {
    //MARK: - Properties
    weak var delegate:LocationInputActivationViewDelegate?
    private let indicatorView: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        return view
    }()
    
    private let placeHolder: UILabel = {
        let label = UILabel ()
        label.text = "您想去哪呢？ "
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = .systemGray
        return label
    }()
    
    //MARK: - LifeCycle
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .white
        addShadow()
        
        addSubview(indicatorView)
//self 表示這整個class 然後整個class init 的部分就是這個frame
        indicatorView.anchor(left:self.leftAnchor, paddingLeft: 8)
        indicatorView.centerY(inView: self)
        indicatorView.setDimensions(height: 6, width: 6)
        
        addSubview(placeHolder)
        placeHolder.anchor(left:indicatorView.rightAnchor, paddingLeft: 16)
        placeHolder.centerY(inView: self)
//加入點擊的手勢識別功能並將功能加入view當中
        let tap = UITapGestureRecognizer(target: self, action: #selector(handlePresentTapGesture))
        addGestureRecognizer(tap)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: - Selectors
    @objc func handlePresentTapGesture () {
//要功能發生的地點(使用這個func的位置)代理給HomeController
        delegate?.presentLocationInputView()
    }
}
