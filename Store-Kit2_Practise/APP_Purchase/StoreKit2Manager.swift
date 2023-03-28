//
//  StireKit2Manager.swift
//  Store-Kit2_Practise
//
//  Created by Gary on 2023/3/23.
//

import Foundation
import StoreKit




enum SubscriptionErroe: Error{
    case pending
    case userCancelled
    case failedVerification
}




class StoreKit2Manager: NSObject {
    
    
   
    
    static let shared = StoreKit2Manager()
    weak var getProductDelegate: GetProduct?
    weak var getPurchasedProductStatusDelegate: GetPurchasedProductStatus?
    
    let subscriptionProductId = "subscriptionProduct"
    let consumableProductId = "consumableProduct"
    var subscriptionProductList = [Product]()
    var consumableProductList = [Product]()
    var purchasedSubscriptionProductList = [Product]()
    var purchasedConsumableProductList = [Product]()
    
    var updateListenerTask: Task<Void, Error>? = nil
    
    override init() {
        super.init()
        updateListenerTask = listenForTransactions()
        Task {
            await requestProduct()
            await upDatePurchaseIdentifier()
        }
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    
    @MainActor
    func requestProduct() async {
        do {
            let storeProduct = try await Product.products(for: [subscriptionProductId,consumableProductId])
            
            for product in storeProduct {
                switch product.type {
                case .consumable:
                    consumableProductList.append(product)
                case .nonRenewable:
                    subscriptionProductList.append(product)
                default:
                    print("Unknow Product")
                }
            }
            getProductDelegate?.getConsumableProducts(consumableProductList)
            getProductDelegate?.getSubscribeProducts(subscriptionProductList)
        } catch {
            print("Failed product request: \(error)")
        }
    }
    

    func purchase(_ product: Product) async throws -> Transaction? {
        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
           
            await upDatePurchaseIdentifier()
            await transaction.finish()
            return transaction
        case .pending, .userCancelled:
            return nil
        default:
            return nil
        }
    }
    
    //監聽交易
    func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try self.checkVerified(result)
                    await self.upDatePurchaseIdentifier()
                    
                    await transaction.finish()
                } catch {
                    print("Transaction failed verification")
                }
            }
        }
    }
    
    //更新已購買的商品狀態
    func upDatePurchaseIdentifier() async {
        var purchasedConsumableProduct = [Product]()
        var purchasedSubscriptionProduct = [Product]()
        for await result in Transaction.currentEntitlements {
            do {
                let transcation = try checkVerified(result)
                
                switch transcation.productType {
                case .consumable:
                    if let consumableProduct = consumableProductList.first(where: { $0.id == transcation.productID}) {
                        purchasedConsumableProduct.append(consumableProduct)
                    }
                case .nonRenewable:
                    if let subscriptionProduct = subscriptionProductList.first(where: { $0.id == transcation.productID}) {
                        let currentDate = Date()
                        let expirationDate = Calendar(identifier: .chinese).date(byAdding: DateComponents(minute: 1), to: transcation.purchaseDate)!
                       print(currentDate)
                        if currentDate < expirationDate {
                            purchasedSubscriptionProduct.append(subscriptionProduct)
                        }
                    }
                case .autoRenewable:
                    break
                default:
                    break
                }
                
            } catch {
                print("\(error)")
            }
        }
        purchasedConsumableProductList = purchasedConsumableProduct
        purchasedSubscriptionProductList = purchasedSubscriptionProduct
        getPurchasedProductStatusDelegate?.getConsumableProductsPurchasedStatus(purchasedConsumableProductList)
        getPurchasedProductStatusDelegate?.getSubscribeProductsPurchasedStatus(purchasedSubscriptionProductList)
    }
    
    
    func isPurchase(_ productId: String) async throws -> Bool {
        guard let result = await Transaction.latest(for: productId) else {
            return false
        }
        
        let transcation = try checkVerified(result)
        return transcation.revocationDate == nil && !transcation.isUpgraded
    }
    

    
    
    func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
            //Check if the transaction passes StoreKit verification.
            switch result {
            case .unverified:
                //StoreKit has parsed the JWS but failed verification. Don't deliver content to the user.
                throw SubscriptionErroe.failedVerification
            case .verified(let safe):
                //If the transaction is verified, unwrap and return it.
                return safe
            }
    }
    
    
    func sortByPrice(_ product: [Product]) -> [Product] {
        product.sorted { return $0.price < $1.price }
    }
        
    
}

protocol GetProduct: NSObjectProtocol {
    func getConsumableProducts(_ product: [Product])
    func getSubscribeProducts(_ product: [Product])
}

protocol GetPurchasedProductStatus: NSObjectProtocol{
    func getConsumableProductsPurchasedStatus(_ purchasedProduct: [Product])
    func getSubscribeProductsPurchasedStatus(_ purchasedProduct: [Product])
}
