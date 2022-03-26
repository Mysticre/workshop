//
//  LaunchView.swift
//  UberClone
//
//  Created by Mysticre on 2022/3/20.
//

import UIKit

class LaunchView: UIViewController {
    //MARK: - Properties
    private let imageView: UIImageView = {
        let frame = CGRect(x: 0, y: 0, width: 150, height: 150)
        let imageView = UIImageView(frame: frame)
        imageView.image = UIImage(named: "greenCircle")
        return imageView
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.init(name: "TESLA", size: 30)
        label.textColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        label.text = "TELEPORT"
        return label
    }()
    
    //MARK: - LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        configureLayout()
    }
    
    //MARK: - Helper Functions
    func configureUI() {
        view.backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
        view.addSubview(imageView)
        view.addSubview(titleLabel)
        titleLabel.anchor(top:imageView.bottomAnchor, paddingTop: 32)
        titleLabel.centerX(inView: view, constant: 12)
    }
    
    func configureLayout() {
        imageView.center = view.center
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            self.animate()
        }
    }
    
    private func animate() {
        UIView.animate(withDuration: 2.5) {
            let size = self.view.frame.width * 3
            //size包含寬度與高度的結構
            let diffX = size - self.view.frame.size.width
            let diffY = self.view.frame.size.height - size
            self.imageView.frame = CGRect(x: -(diffX / 2), y: diffY / 2, width: size, height: size)
        }
        UIView.animate(withDuration: 1.5) {
            self.imageView.alpha = 0
            self.titleLabel.alpha = 0
        } completion: { (_) in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                UIView.animate(withDuration: 2.5) {
                    self.dismiss(animated: true) {
                        UIView.animate(withDuration: 0.8) {
                            self.view.backgroundColor = UIColor.customColor(red: 0, green: 93, blue: 68)
                        }
                    }
                }
            }
        }
    }
}

