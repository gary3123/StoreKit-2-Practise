//
//  MainViewController.swift
//  Store-Kit2_Practise
//
//  Created by Gary on 2023/3/23.
//

import UIKit
import StoreKit

class MainViewController: UIViewController {
    
    enum Product: String, CaseIterable {
        case consumableProduct = "consumableProduct"
        case subscriptionProduct = "subscriptionProduct"
    }
    
//    let productsRequest: SKProductsRequest?
   
  
    override func viewDidLoad() {
        super.viewDidLoad()
      
    }

   

    @IBAction func clickSend() {
        if SKPaymentQueue.canMakePayments() {
            let set: Set<String> = [Product.consumableProduct.rawValue]
            let productRequest = SKProductsRequest(productIdentifiers: set)
            productRequest.delegate = self
            productRequest.start()
        }
    }
    
    @IBAction func clickSubscribe() {
        if SKPaymentQueue.canMakePayments() {
            let set: Set<String> = [Product.subscriptionProduct.rawValue]
            let productRequest = SKProductsRequest(productIdentifiers: set)
            productRequest.delegate = self
            productRequest.start()
        }
    }

}

extension MainViewController: SKProductsRequestDelegate, SKPaymentTransactionObserver {
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        if let oProduct = response.products.first {
            print("Product is available. ")
            
            purchase(product: oProduct)
        } else {
            print("Product is not available.")
        }
    }
    
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchasing:
                print("Customer is in the proccess of purchase. ")
            case .purchased:
                SKPaymentQueue.default().finishTransaction(transaction)
                print("Purchased")
            case .failed:
                SKPaymentQueue.default().finishTransaction(transaction)
                print("Faild")
            case .restored:
                print("restored")
            case .deferred:
                print("deferred")
            default:
                break
            }
        }
    }
    
    func purchase(product: SKProduct) {
        let payment = SKPayment(product: product)
        SKPaymentQueue.default().add(self)
        SKPaymentQueue.default().add(payment)
    }
    
    
}
