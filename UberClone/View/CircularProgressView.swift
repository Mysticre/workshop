//
//  CircularProgressView.swift
//  UberClone
//
//  Created by Mysticre on 2022/3/6.
//

import UIKit

class CircularProgressView: UIView {
    //MARK:- Properties
    var progressLayer: CAShapeLayer!
    var trackLayer: CAShapeLayer!
    var pulsatingLayer: CAShapeLayer!

    //MARK: - LifeCycle
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureCircleLayers()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: - Helper Functions
    //圖層是用Layer圖層畫圖不同於View
    func configureCircleLayers() {
        //底層
        pulsatingLayer = setCircleShapeLayer(strokeColor: .clear, fillColor: .pulsatingFillColor)
        layer.addSublayer(pulsatingLayer)
        //第二層
        trackLayer = setCircleShapeLayer(strokeColor: .trackStrokeColor, fillColor: .clear)
        layer.addSublayer(trackLayer)
        trackLayer.strokeEnd = 1 //停止渲染的地點 0~1為一個圓的週期
        //第三層(最外面的)
        progressLayer = setCircleShapeLayer(strokeColor: .outlineStrokeColor, fillColor: .clear)
        layer.addSublayer(progressLayer)
    }
    //創造出園型態的func
    func setCircleShapeLayer(strokeColor:UIColor, fillColor:UIColor) -> CAShapeLayer {
        let layer = CAShapeLayer() //可畫出在指定坐標圖形的物件
        let centerPoint = CGPoint(x: 0, y: 32)
        // .pi = 180度 /2 表示從90度位置畫圓 用Bezier畫出圓形路徑
        let circularPath = UIBezierPath(arcCenter: centerPoint, radius: self.frame.width / 2.5, startAngle: -(.pi / 2), endAngle: 2.5 * .pi , clockwise: true)
        layer.path = circularPath.cgPath //路徑物件
        layer.strokeColor = strokeColor.cgColor //顏色物件
        layer.lineWidth = 12
        layer.fillColor = fillColor.cgColor
        layer.lineCap = .round //線條結尾的樣式
        layer.position = self.center
        return layer
    }
    
    func animatePulsatingLayer() {
        let animation = CABasicAnimation(keyPath: "transform.scale")
        animation.toValue = 1.5//擴大scale的範圍為原本的1倍
        animation.duration = 0.8 // 0.8秒完成一個scale的循環
        animation.timingFunction = CAMediaTimingFunction(name: .easeOut) //時間開始會加快遞增然後變慢
        animation.autoreverses = true //倒轉播放, 彈出去再回來
        animation.repeatCount = Float.infinity //浮點數值, 無限播放下去
        pulsatingLayer.add(animation, forKey: "pulsing")
    }
    //創造出圈圈倒數進行的動畫效果
    func setProgressWithAnimation(duration: TimeInterval, value: Float, completion: @escaping() -> Void) {
        CATransaction.begin() //CATransaction的動畫模塊, 從begin執行觀察到commit所有行為
        CATransaction.setCompletionBlock(completion) //完成動畫後要做什麼事情
        
        let animation = CABasicAnimation(keyPath: "strokeEnd") //設定動畫的基本屬性條件的object keyPath是繪製得屬性 strokeEnd 表示從起始到結束得屬性
        animation.duration = duration //循環1個週期的時間
        animation.fromValue = 1 //動畫開始的起始值 圓的週期
        animation.toValue = value //動畫結束的終了值 通常為0 如果是0.5就會進行到一半停止 要配合strokeEnd才會完整
        animation.timingFunction = CAMediaTimingFunction(name: .linear) //時間緩衝函數(時間/變量的關係)
        progressLayer.strokeEnd = CGFloat(value) //停止載入路線的結束值
        progressLayer.add(animation, forKey: "animateProgress") //加入動畫特效 add的key是自行創造的
        
        CATransaction.commit()
    }
}
