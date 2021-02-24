import Foundation


// MARK: - StorageType DataModel Specific Extensions for Deletions
//
public extension StorageType {

    // MARK: - Products

    /// Deletes all of the stored Products for the provided siteID.
    ///
    func deleteProducts(siteID: Int64) {
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

    /// Deletes single stored Product Variation for the provided siteID and productVariationID.
    ///
    func deleteProductVariation(siteID: Int64, productVariationID: Int64) {
        guard let productVariation = loadProductVariation(siteID: siteID, productVariationID: productVariationID) else {
            return
        }

        deleteObject(productVariation)
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

    /// Deletes all of the stored Product Categories that don't have an active product relationship
    ///
    func deleteUnusedProductCategories(siteID: Int64) {
        let categoriesWithNoAssociatedProducts = loadProductCategories(siteID: siteID).filter { category in
            guard let products = category.products else {
                return true
            }
            return products.isEmpty
        }
        categoriesWithNoAssociatedProducts.forEach { category in
            deleteObject(category)
        }
    }

    /// Deletes all of the stored Product Tags that don't have an active product relationship
    ///
    func deleteUnusedProductTags(siteID: Int64) {
        let tagsWithNoAssociatedProducts = loadProductTags(siteID: siteID).filter { $0.products == nil || $0.products?.isEmpty == true }
        tagsWithNoAssociatedProducts.forEach { tag in
            deleteObject(tag)
        }
    }

    /// Deletes all the stored Product Tags with the specified IDs
    ///
    func deleteProductTags(siteID: Int64, ids: [Int64]) {
        let tagsWithSpecifiedIDs = loadProductTags(siteID: siteID).filter { ids.contains($0.tagID) }
        tagsWithSpecifiedIDs.forEach { tag in
            deleteObject(tag)
        }
    }

    /// Deletes all of the stored Product Attributes that don't have an active product relationship
    ///
    func deleteUnusedProductAttributes(siteID: Int64) {
        let attributesWithNoAssociatedProduct = loadProductAttributes(siteID: siteID).filter { attribute in
            guard attribute.product != nil else {
                return true
            }
            return false
        }
        attributesWithNoAssociatedProduct.forEach { attribute in
            deleteObject(attribute)
        }
    }

    // MARK: - Product Reviews

    /// Deletes all of the stored Reviews for the provided siteID.
    ///
    func deleteProductReviews(siteID: Int64) {
        guard let productReviews = loadProductReviews(siteID: siteID) else {
            return
        }
        for review in productReviews {
            deleteObject(review)
        }
    }
}
