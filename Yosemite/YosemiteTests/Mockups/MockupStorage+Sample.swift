import Foundation
import Yosemite


// MARK: - MockupStorage Sample Entity Insertion Methods
//
extension MockupStorageManager {

    /// Inserts a new (Sample) account into the specified context.
    ///
    @discardableResult
    func insertSampleAccount() -> StorageAccount {
        let newAccount = viewStorage.insertNewObject(ofType: StorageAccount.self)
        newAccount.userID = Int64(arc4random())
        newAccount.displayName = "Yosemite"
        newAccount.email = "yosemite@yosemite"
        newAccount.gravatarUrl = "https://something"
        newAccount.username = "yosemite"

        return newAccount
    }

    /// Inserts a new (Sample) Product into the specified context.
    ///
    @discardableResult
    func insertSampleProduct(readOnlyProduct: Product) -> StorageProduct {
        let newProduct = viewStorage.insertNewObject(ofType: StorageProduct.self)
        newProduct.update(with: readOnlyProduct)

        return newProduct
    }

    /// Inserts a new (Sample) ProductVariation into the specified context.
    ///
    @discardableResult
    func insertSampleProductVariation(readOnlyProductVariation: ProductVariation) -> StorageProductVariation {
        let newProductVariation = viewStorage.insertNewObject(ofType: StorageProductVariation.self)
        newProductVariation.update(with: readOnlyProductVariation)

        return newProductVariation
    }

    /// Inserts a new (Sample) ProductShippingClass into the specified context.
    ///
    @discardableResult
    func insertSampleProductShippingClass(readOnlyProductShippingClass: ProductShippingClass) -> StorageProductShippingClass {
        let newProductShippingClass = viewStorage.insertNewObject(ofType: StorageProductShippingClass.self)
        newProductShippingClass.update(with: readOnlyProductShippingClass)

        return newProductShippingClass
    }
}
