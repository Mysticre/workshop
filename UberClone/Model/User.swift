//
//  User.swift
//  UberClone
//
//  Created by Mysticre on 2022/1/3.
//

import Foundation
import Firebase
import CoreLocation

//把accpuntType用enum整理
enum AccountType: Int {
    case driver
    case passenger
}
//初始化一個object
struct User {
    let fullname: String
    let email: String
    var accountType: AccountType!
    var location: CLLocation? //有?代表不一定需要 init出來
    var home: String?
    var work:String?
    let uid: String
//初始化成字典 變數如果沒值就寫nil
    init(uid: String, dictionary: [String:Any]) {
// ??是如果存在就回傳前面的 不存在就回傳 後面的
        self.uid = uid
        self.fullname = dictionary["fullname"] as? String ?? " "
        self.email = dictionary["email"] as? String ?? " "
//改寫accountType為enum的形式
//if let 的表達方式 若沒有值則會上傳nil到資料庫 若是用?? 則是上傳" "空白值 兩者意義不同
        if let accountTypeIndex = dictionary["accountType"] as? Int {
            self.accountType = AccountType(rawValue: accountTypeIndex)
        }
        if let homeLocation = dictionary["home"] as? String {
            self.home = homeLocation
        }
        if let workLocation = dictionary["work"] as? String {
            self.work = workLocation
        }
    }
}

