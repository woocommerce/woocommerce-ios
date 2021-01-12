import Foundation
import Yosemite


// MARK: - MockStorageManager Sample Entity Insertion Methods
//
extension MockStorageManager {

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

    /// Inserts a new (Sample) ProductCategory into the specified context.
    ///
    @discardableResult
    func insertSampleProductCategory(readOnlyProductCategory: ProductCategory) -> StorageProductCategory {
        let newProductCategory = viewStorage.insertNewObject(ofType: StorageProductCategory.self)
        newProductCategory.update(with: readOnlyProductCategory)

        return newProductCategory
    }

    /// Inserts a new (Sample) ProductTag into the specified context.
    ///
    @discardableResult
    func insertSampleProductTag(readOnlyProductTag: ProductTag) -> StorageProductTag {
        let newProductTag = viewStorage.insertNewObject(ofType: StorageProductTag.self)
        newProductTag.update(with: readOnlyProductTag)

        return newProductTag
    }

    /// Inserts a new (Sample) ProductAttribute into the specified context.
    ///
    @discardableResult
    func insertSampleProductAttribute(readOnlyProductAttribute: ProductAttribute) -> StorageProductAttribute {
        let newProductAttribute = viewStorage.insertNewObject(ofType: StorageProductAttribute.self)
        newProductAttribute.update(with: readOnlyProductAttribute)

        return newProductAttribute
    }

    /// Inserts a new (Sample) `ProductAttributeTerm`. and links it to a parent `ProductAttribute` if available.
    ///
    @discardableResult
    func insertSampleProductAttributeTerm(readOnlyTerm: ProductAttributeTerm, onAttributeWithID attributeID: Int64) -> StorageProductAttributeTerm {
        let newProductAttributeTerm = viewStorage.insertNewObject(ofType: StorageProductAttributeTerm.self)
        newProductAttributeTerm.update(with: readOnlyTerm)

        if let attribute = viewStorage.loadProductAttribute(siteID: readOnlyTerm.siteID, attributeID: attributeID) {
            newProductAttributeTerm.attribute = attribute
        }

        return newProductAttributeTerm
    }

    /// Inserts a new (Sample) Order into the specified context.
    ///
    @discardableResult
    func insertSampleOrder(readOnlyOrder: Order) -> StorageOrder {
        let newOrder = viewStorage.insertNewObject(ofType: StorageOrder.self)
        newOrder.update(with: readOnlyOrder)

        return newOrder
    }
}
