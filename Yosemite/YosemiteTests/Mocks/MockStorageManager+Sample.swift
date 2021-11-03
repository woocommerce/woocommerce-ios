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

    /// Inserts a new AccountSettings into the specified context.
    ///
    @discardableResult
    func insertSampleAccountSettings(readOnlyAccountSettings: AccountSettings) -> StorageAccountSettings {
        let newAccountSettings = viewStorage.insertNewObject(ofType: StorageAccountSettings.self)
        newAccountSettings.update(with: readOnlyAccountSettings)

        return newAccountSettings
    }

    /// Inserts a new (Sample) Payment Gateway Account into the specified context.
    ///
    @discardableResult
    func insertSamplePaymentGatewayAccount(readOnlyAccount: PaymentGatewayAccount) -> StoragePaymentGatewayAccount {
        let newAccount = viewStorage.insertNewObject(ofType: StoragePaymentGatewayAccount.self)
        newAccount.update(with: readOnlyAccount)

        return newAccount
    }

    /// Inserts a new (Sample) Product into the specified context.
    ///
    @discardableResult
    func insertSampleProduct(readOnlyProduct: Product) -> StorageProduct {
        let newProduct = viewStorage.insertNewObject(ofType: StorageProduct.self)
        newProduct.update(with: readOnlyProduct)

        let categories: [StorageProductCategory] = readOnlyProduct.categories.compactMap {
            let productCategory = viewStorage.insertNewObject(ofType: StorageProductCategory.self)
            productCategory.update(with: $0)

            return productCategory
        }

        newProduct.categories = Set(categories)

        return newProduct
    }

    /// Inserts a new (Sample) ProductVariation into the specified context.
    /// Adds it to a product if required.
    ///
    @discardableResult
    func insertSampleProductVariation(readOnlyProductVariation: ProductVariation, on readOnlyProduct: Product? = nil) -> StorageProductVariation {
        let newProductVariation = viewStorage.insertNewObject(ofType: StorageProductVariation.self)
        newProductVariation.update(with: readOnlyProductVariation)

        if let readOnlyProduct = readOnlyProduct {
            let newProduct = viewStorage.insertNewObject(ofType: StorageProduct.self)
            newProduct.update(with: readOnlyProduct)
            newProductVariation.product = newProduct
        }

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

    /// Inserts a new (Sample) site into the specified context.
    ///
    @discardableResult
    func insertSampleSite(readOnlySite: Site) -> StorageSite {
        let newSite = viewStorage.insertNewObject(ofType: StorageSite.self)
        newSite.update(with: readOnlySite)

        return newSite
    }

    /// Inserts a new (Sample) SitePlugin into the specified context.
    /// Administrators can fetch installed plugins as SitePlugins. Shop Managers cannot.
    ///
    @discardableResult
    func insertSampleSitePlugin(readOnlySitePlugin: SitePlugin) -> StorageSitePlugin {
        let newPlugin = viewStorage.insertNewObject(ofType: StorageSitePlugin.self)
        newPlugin.update(with: readOnlySitePlugin)

        return newPlugin
    }

    /// Inserts a new (Sample) SystemPlugin into the specified context.
    /// Shop Managers AND Administrators can fetch installed plugins as SystemPlugins.
    ///
    @discardableResult
    func insertSampleSystemPlugin(readOnlySystemPlugin: SystemPlugin) -> StorageSystemPlugin {
        let newPlugin = viewStorage.insertNewObject(ofType: StorageSystemPlugin.self)
        newPlugin.update(with: readOnlySystemPlugin)

        return newPlugin
    }

    /// Inserts a new (Sample) Setting into the specified context.
    ///
    @discardableResult
    func insertSampleSiteSetting(readOnlySiteSetting: SiteSetting) -> StorageSiteSetting {
        let newSetting = viewStorage.insertNewObject(ofType: StorageSiteSetting.self)
        newSetting.update(with: readOnlySiteSetting)

        return newSetting
    }

    /// Inserts new sample countries into the specified context.
    ///
    @discardableResult
    func insertSampleCountries(readOnlyCountries: [Country]) -> [StorageCountry] {
        let storedCountries: [StorageCountry] = readOnlyCountries.map { readOnlyCountry in
            let newCountry = viewStorage.insertNewObject(ofType: StorageCountry.self)
            newCountry.update(with: readOnlyCountry)
            readOnlyCountry.states.forEach { readOnlyState in
                let newState = viewStorage.insertNewObject(ofType: StorageStateOfACountry.self)
                newState.update(with: readOnlyState)
                newCountry.states.insert(newState)
            }

            return newCountry
        }
        return storedCountries
    }
}
