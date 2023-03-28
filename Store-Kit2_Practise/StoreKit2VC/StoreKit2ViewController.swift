//
//  StoreKit2ViewController.swift
//  Store-Kit2_Practise
//
//  Created by Gary on 2023/3/27.
//

import UIKit
import StoreKit
import LocalAuthentication

class StoreKit2ViewController: UIViewController {

    @IBOutlet weak var label: UILabel?
    @IBOutlet weak var textField: UITextField?
    @IBOutlet weak var sendButton: UIButton?
    @IBOutlet weak var subscribeButton: UIButton?
    
    var consumableProducts = [Product]()
    var subscriptionProducts = [Product]()
    var purchasedConsumableProducts = [Product]()
    var purchasedSubscriptionProducts = [Product]()
    var subscribeStatus = false
    let manager = StoreKit2Manager.shared
    let biometrics = LAContext()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        manager.getProductDelegate = self
        manager.getPurchasedProductStatusDelegate = self
//        BiometricsAuthentication()
        Task {
            await setupUI()
        }
        
       
    }
    
    override func viewWillAppear(_ animated: Bool) {
      
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
    
    func setupUI() async {
        await updateSubscriptionStatus()
        updatePurchasedUI()
    }
    
   
    func updateSubscriptionStatus() async {
        await StoreKit2Manager.shared.upDatePurchaseIdentifier()
        if purchasedSubscriptionProducts.isEmpty {
            subscribeStatus = false
//            print("do")
        } else {
            subscribeStatus = true
            print("\(purchasedSubscriptionProducts[0].displayName)")
//            print("do")
        }

    }
    
    
    //生物辨識
    func BiometricsAuthentication() {
        biometrics.localizedCancelTitle = "關閉應用程式"
        biometrics.localizedFallbackTitle = "使用密碼登入"
        var error: NSError?
        if biometrics.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            let reason = "關閉應用程式或是使用密碼登入"
            biometrics.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, error in
                guard success else {
                    exit(0)
                }
            }
        }
    }
    
    func updatePurchasedUI() {
        if subscribeStatus == false {
            self.sendButton?.tintColor = .systemBlue
            self.subscribeButton?.tintColor = .systemBlue
            self.subscribeButton?.setTitle("Subscribe", for: .normal)
            print("已更新ＵＩ")
        } else {
          
            self.subscribeStatus = true
            self.sendButton?.tintColor = .systemGreen
            self.subscribeButton?.tintColor = UIColor.systemGreen
            self.subscribeButton?.setImage(UIImage(systemName: "checkmark"), for: .normal)
            self.subscribeButton?.setTitle("", for: .normal)
            self.subscribeButton?.isUserInteractionEnabled = false
            print("已更新ＵＩ")
        }
    }
    
    
    func fetchProduct() async {
        await StoreKit2Manager.shared.requestProduct()
        self.view.backgroundColor = .white

    }
    
//    func isPurchased() async {
//        let productId = subscriptionProducts[0].id
//        do {
//            subscribeStatus = try await StoreKit2Manager.shared.isPurchase(productId)
//            updatePurchasedUI()
//        } catch {
//
//        }
//
//    }
    

    @IBAction func clickSend() {
        if subscribeStatus == false {
            Task {
                do{
                    let consumableProducts = consumableProducts[0]
                    if (try await StoreKit2Manager.shared.purchase(consumableProducts)) != nil {
                        label?.text = textField?.text
                    }
                } catch {
                }
            }
        } else {
            label?.text = textField?.text
        }
    }
    
    @IBAction func clickSubscribe() {
//        if subscribeStatus == false {
//            Task {
//                do{
//                    let subscriptionProducts = subscriptionProducts[0]
//                    if (try await StoreKit2Manager.shared.purchase(subscriptionProducts)) != nil {
//                        await isPurchased()
//                    }
//                } catch {
//
//                }
//            }
//        }
        print("陣列為空：\(purchasedSubscriptionProducts.isEmpty)")
        if purchasedSubscriptionProducts.isEmpty {
            Task {
                do {
                    let subscriptionProducts = subscriptionProducts[0]
                    try await StoreKit2Manager.shared.purchase(subscriptionProducts)
                    subscribeStatus = true
                    updatePurchasedUI()
                } catch {
                    
                }
            }
        } else {
           
        }
    }

  

}


extension StoreKit2ViewController: GetProduct {
    func getSubscribeProducts(_ product: [Product]) {
        subscriptionProducts = product
    }
    
    func getConsumableProducts(_ product: [Product]) {
        consumableProducts = product
    }
} 



extension StoreKit2ViewController: GetPurchasedProductStatus {
    func getConsumableProductsPurchasedStatus(_ purchasedProduct: [Product]) {
        purchasedConsumableProducts = purchasedProduct
    }
    
    func getSubscribeProductsPurchasedStatus(_ purchasedProduct: [Product]) {
       
        purchasedSubscriptionProducts = purchasedProduct
//        print("經過delegate")
//        if purchasedSubscriptionProducts.isEmpty {
//            print("purchasedSubscriptionProducts 是空的")
//        } else {
//            print("purchasedSubscriptionProducts 不是空的")
//        }
    }
}
