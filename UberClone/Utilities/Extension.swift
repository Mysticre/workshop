//
//  Extension.swift
//  UberClone
//
//  Created by Mysticre on 2021/9/11.
//

import Foundation
import UIKit
import MapKit

enum SwitchView {
    case background
    case header
    
    init(){
        self = .background
    }
}

extension UIView {
    func myContainerView(imagePic:UIImage, emailTField: UITextField? = nil, segControl: UISegmentedControl? = nil) -> UIView{
        let view = UIView()
        
        let imageView = UIImageView()
        imageView.image = imagePic
        imageView.alpha = 0.87
        view.addSubview(imageView)
        
        if let emailTField = emailTField {
            imageView.centerY(inView: view)
            imageView.anchor(left:view.leftAnchor , paddingLeft: 8,  width: 24, height: 24)
            
            view.addSubview(emailTField)
            emailTField.centerY(inView: view)
            emailTField.anchor(bottom:view.bottomAnchor, left:imageView.rightAnchor, right: view.rightAnchor, paddingBottom: 8, paddingLeft: 8)
        }
        
        if let segControl = segControl{
            imageView.anchor(top: view.topAnchor, left: view.leftAnchor, paddingTop: -8,  paddingLeft: 8, width:24, height: 24)
            
            view.addSubview(segControl)
            segControl.anchor(left:view.leftAnchor, right: view.rightAnchor, paddingLeft: 24, paddingRight: 24)
            segControl.centerY(inView: view, constant: 8 )
        }
        
        let separatorView = UIView()
        separatorView.backgroundColor = .lightGray
        
        view.addSubview(separatorView)
        separatorView.anchor(bottom:view.bottomAnchor, left: view.leftAnchor, right: view.rightAnchor, paddingLeft: 8, paddingRight: 8,  height: 1)
            return view
    }
    
    func anchor(top:NSLayoutYAxisAnchor? = nil,
                 bottom:NSLayoutYAxisAnchor? = nil,
                 left:NSLayoutXAxisAnchor? = nil,
                 right:NSLayoutXAxisAnchor? = nil,
                 paddingTop:CGFloat = 0,
                 paddingBottom:CGFloat = 0,
                 paddingLeft:CGFloat = 0,
                 paddingRight:CGFloat = 0,
                 width:CGFloat? = nil,
                 height:CGFloat? = nil
                 ){
        translatesAutoresizingMaskIntoConstraints = false
        
        if let top = top {
            topAnchor.constraint(equalTo: top, constant: paddingTop ).isActive = true
        }
        
//由下往上算 要-
        if let bottom = bottom {
            bottomAnchor.constraint(equalTo: bottom, constant: -paddingBottom).isActive = true
        }
        
        if let left = left {
            leftAnchor.constraint(equalTo: left, constant: paddingLeft ).isActive = true
        }
        
//由右往左算 要-
        if let right = right {
            rightAnchor.constraint(equalTo: right, constant: -paddingRight ).isActive = true
        }
        
        if let width = width {
            widthAnchor.constraint(equalToConstant: width).isActive = true
        }
        
        if let height = height {
            heightAnchor.constraint(equalToConstant: height).isActive = true
        }
    }

    func centerX(inView view: UIView, constant: CGFloat = 0){
        translatesAutoresizingMaskIntoConstraints = false
        centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: constant).isActive = true
    }
    
    func centerY(inView view: UIView, constant: CGFloat = 0){
        translatesAutoresizingMaskIntoConstraints = false
        centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: constant).isActive = true
    }
    
//新增方便增加高度(height)和寬度(width)的func
    func setDimensions(height:CGFloat, width:CGFloat){
        translatesAutoresizingMaskIntoConstraints = false
        heightAnchor.constraint(equalToConstant: height).isActive = true
        widthAnchor.constraint(equalToConstant: width).isActive = true
    }
    
    func addShadow() {
//動畫渲染變數(CoreAnimation)陰影顏色
        layer.shadowColor = UIColor.black.cgColor
//陰影透明度,數字越大越暗
        layer.shadowOpacity = 0.65
//陰影偏移量(厚度)
        layer.shadowOffset = CGSize(width: 0.5, height: 0.5)
//漸層顯示不要裁切
        layer.masksToBounds = false
    }
}
//擴增 UITextField
extension UITextField {
    func myTextField(placeHolder:String, isSecureTextEntry: Bool? = nil) -> UITextField{
        let tf = UITextField()
        tf.borderStyle = .none
        tf.font = UIFont.systemFont(ofSize: 16)
        tf.textColor = .white
        tf.keyboardAppearance = .dark
        tf.isSecureTextEntry = isSecureTextEntry ?? false
        tf.attributedPlaceholder = NSAttributedString(string: placeHolder, attributes: [NSAttributedString.Key.foregroundColor : UIColor.lightGray])
        return tf
    }
}

extension UIColor {
//必須加上static讓新增fuction的數值能夠馬上被同一擴增的常數使用,否則下方同一擴增會成self.UIColor
    static func customColor(red:CGFloat, green:CGFloat, blue:CGFloat) -> UIColor{
        return UIColor.init(red: red/255, green: green/255, blue: blue/255, alpha: 1)
    }
//必須加上static來確保記憶體分配
    static let customBackgroundColor = UIColor.customColor(red: 25, green: 25, blue: 25)
    static let customBlueColor = UIColor.customColor(red: 17, green: 154, blue: 237)
    static let outlineStrokeColor = UIColor.customColor(red: 49, green: 253, blue: 158)
    static let trackStrokeColor = UIColor.customColor(red: 15, green: 137, blue: 80)
    static let pulsatingFillColor = UIColor.customColor(red: 64, green: 192, blue: 132)
}

extension CGColor{
    static func customCGColor(red: CGFloat, green: CGFloat, blue: CGFloat) -> CGColor {
        return CGColor.init(red: red/255, green: green/255, blue: blue/255, alpha: 1)
    }
}

extension UIButton {
    func myCustomButton(title:String) -> UIButton{
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.setTitleColor(UIColor(white: 1, alpha: 0.87), for: .normal)
        button.backgroundColor = .customBlueColor
        button.layer.cornerRadius = 6
        button.heightAnchor.constraint(equalToConstant: 50).isActive = true
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize:15)
        return button
    }
}

extension MKPlacemark {
    var placeSpotInfo: String? {
        get {
        guard let tho = thoroughfare else {return nil}
        guard let sub = subThoroughfare else {return nil}
        guard let location = locality else {return nil}
        guard let auth = administrativeArea else {return nil}
        return "\(tho) \(sub), \(location), \(auth)"
        }
    }
}

extension MKMapView {
    func generateAnnotation(withCoordinates coordinates: CLLocationCoordinate2D) {
        //要用MKPointAnnotation(MKpoint是以文字標示的地點表示方式)
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinates
        addAnnotation(annotation)
        //可特別標示Anno的圖示為較大圖示
        selectAnnotation(annotation, animated: true)
    }
    
    func zoomInMap(annotationsInRect:[MKAnnotation]) {
//先創造一個null的地圖長方形區域
        var zoomRect = MKMapRect.null
//針對每個Annotation Array內的東西進行 1.座標擷取 2.創造MapRect
        annotationsInRect.forEach { (anno) in
            let annoPoint = MKMapPoint(anno.coordinate)
            let mapRect = MKMapRect(x: annoPoint.x, y: annoPoint.y, width: 1.0 , height: 1.0 )
//將兩個Rect合而為一
             zoomRect = zoomRect.union(mapRect)
        }
//開啟一個可視的MapRect來標出特定區域
        let edgeInsets = UIEdgeInsets(top: 100, left: 150, bottom: 300, right: 150)
        setVisibleMapRect(zoomRect, edgePadding: edgeInsets, animated: true)
    }
}

//用擴展的方式建立一個Passenger按下後的讀取頁面
extension UIViewController {
    func ShouldPresentLoadingView(_ present: Bool, message: String? = nil){
        if present {
            let loadingView = UIView()
            loadingView.frame = self.view.frame //讓Loadingview覆蓋整體的Self.view
            loadingView.backgroundColor = .black
            loadingView.alpha = 0 //一開始不透明而後用動畫轉為漸層
            loadingView.tag = 1 //給予一個標籤序號
        
            let indicator = UIActivityIndicatorView() //可以創造Progressing的效果
            indicator.style = .large //大型顯示
            indicator.center = view.center //把Indicator的中心點置入畫面的中心點

            let label = UILabel()
            label.text = message
            label.font = UIFont.systemFont(ofSize: 24)
            label.textColor = .white
            //將LoadingView加入到View層當中,接著將Indicator+Label加入到LoadingView內,不是在原本的View
            view.addSubview(loadingView)
            loadingView.addSubview(indicator)
            loadingView.addSubview(label)
            label.centerX(inView: view)
            label.anchor(top: indicator.bottomAnchor, paddingTop: 32)
            
            indicator.startAnimating() //開始run動畫特效
            
            UIView.animate(withDuration: 0.3) {
                loadingView.alpha = 0.7
            }
        }else{
            //檢查所有的subviews內容(認上面的標籤序號)將其先透明改為0 接著在全部移除
            view.subviews.forEach { (subview) in
                if subview.tag == 1 {
                    UIView.animate(withDuration: 0.3) {
                        subview.alpha = 0
                    } completion: { _ in
                        subview.removeFromSuperview()
                    }
                }
            }
        }
    }
    
    func presentAlertController (_ title:String, message:String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "確認", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    func gradientBackgound(config:SwitchView, background: UIViewController? = nil, header:UIView? = nil) {
        let backgroundView = UIView()
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [CGColor.customCGColor(red: 0, green: 93, blue: 68),
                                            CGColor.customCGColor(red: 0, green: 0, blue: 0)]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        
        switch config {
        case .background:
            if let background = background{
            gradientLayer.frame =  background.view.frame
            backgroundView.layer.addSublayer(gradientLayer)
            background.view = backgroundView
        }
        case .header:
            if let header = header{
                gradientLayer.frame = header.frame
                backgroundView.layer.addSublayer(gradientLayer)
                view = backgroundView
            }
        }
    }
}
