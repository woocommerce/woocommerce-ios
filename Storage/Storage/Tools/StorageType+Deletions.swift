import Foundation


// MARK: - StorageType DataModel Specific Extensions for Deletions
//
public extension StorageType {

    // MARK: - Products

    /// Deletes all of the stored Products for the provided siteID.
    ///
    func deleteProducts(siteID: Int) {
        guard let products = loadProducts(siteID: siteID) else {
            return
        }
        for product in products {
            deleteObject(product)
        }
    }

    /// Deletes all of the stored Product Variations for the provided siteID and productID.
    ///
    func deleteProductVariations(siteID: Int64, productID: Int64) {
        guard let productVariations = loadProductVariations(siteID: siteID,
                                                            productID: productID) else {
                                                                return
        }
        for productVariation in productVariations {
            deleteObject(productVariation)
        }
    }

    /// Deletes all of the stored Product Shipping Class models for the provided siteID.
    ///
    func deleteProductShippingClasses(siteID: Int64) {
        guard let shippingClasses = loadProductShippingClasses(siteID: siteID) else {
                                                                return
        }
        for shippingClass in shippingClasses {
            deleteObject(shippingClass)
        }
    }
}
