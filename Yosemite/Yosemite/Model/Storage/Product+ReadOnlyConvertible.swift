import Foundation
import Storage


// MARK: - Storage.Product: ReadOnlyConvertible
//
extension Storage.Product: ReadOnlyConvertible {

    /// Updates the Storage.Product with the ReadOnly.
    ///
    public func update(with product: Yosemite.Product) {
        siteID = Int64(product.siteID)
        productID = Int64(product.productID)
        productTypeKey = product.productTypeKey
        name = product.name
        slug = product.slug
        permalink = product.permalink
        dateCreated = product.dateCreated
        dateModified = product.dateModified
        statusKey = product.statusKey
        featured = product.featured
        catalogVisibilityKey = product.catalogVisibilityKey
        fullDescription = product.fullDescription
        briefDescription = product.briefDescription
        sku = product.sku
        price = product.price
        regularPrice = product.regularPrice
        salePrice = product.salePrice
        onSale = product.onSale
        purchasable = product.purchasable
        totalSales = Int64(product.totalSales)
        virtual = product.virtual
        downloadable = product.downloadable
        downloadLimit = Int64(product.downloadLimit)
        downloadExpiry = Int64(product.downloadExpiry)
        externalURL = product.externalURL
        taxStatusKey = product.taxStatusKey
        taxClass = product.taxClass
        manageStock = product.manageStock

        var quantity: String? = nil
        if let stockQuantity = stockQuantity {
            quantity = String(stockQuantity)
        }
        stockQuantity = quantity

        stockStatusKey = product.stockStatusKey
        soldIndividually = product.soldIndividually
        weight = product.weight
        shippingRequired = product.shippingRequired
        shippingTaxable = product.shippingTaxable
        shippingClass = product.shippingClass
        shippingClassID = Int64(product.shippingClassID)
        reviewsAllowed = product.reviewsAllowed
        averageRating = product.averageRating
        ratingCount = Int64(product.ratingCount)
        relatedIDs = product.relatedIDs.map { Int64($0) }
        upsellIDs = product.upsellIDs.map { Int64($0) }
        crossSellIDs = product.crossSellIDs.map { Int64($0) }
        parentID = Int64(product.parentID)
        purchaseNote = product.purchaseNote
        variations = product.variations.map { Int64($0) }
        groupedProducts = product.groupedProducts.map { Int64($0) }
        menuOrder = Int64(product.menuOrder)
        backordersKey = product.backordersKey
        backordersAllowed = product.backordersAllowed
        backordered = product.backordered
    }

    /// Returns a ReadOnly version of the receiver.
    ///
    public func toReadOnly() -> Yosemite.Product {

        // TODO: toReadOnly() all of the children 👇

        let productCategories = [Yosemite.ProductCategory]()
        let productTags = [Yosemite.ProductTag]()
        let productImages = [Yosemite.ProductImage]()
        let productAttributes = [Yosemite.ProductAttribute]()
        let productDefaultAttributes = [Yosemite.ProductDefaultAttribute]()

        var quantity: Int?
        if let stockQuantity = stockQuantity {
            quantity = Int(stockQuantity)
        }

        return Product(siteID: Int(siteID),
                       productID: Int(productID),
                       name: name,
                       slug: slug,
                       permalink: permalink,
                       dateCreated: dateCreated,
                       dateModified: dateModified,
                       productTypeKey: productTypeKey,
                       statusKey: statusKey,
                       featured: featured,
                       catalogVisibilityKey: catalogVisibilityKey,
                       fullDescription: fullDescription,
                       briefDescription: briefDescription,
                       sku: sku,
                       price: price,
                       regularPrice: regularPrice,
                       salePrice: salePrice,
                       onSale: onSale,
                       purchasable: purchasable,
                       totalSales: Int(totalSales),
                       virtual: virtual,
                       downloadable: downloadable,
                       downloadLimit: Int(downloadLimit),
                       downloadExpiry: Int(downloadExpiry),
                       externalURL: externalURL,
                       taxStatusKey: taxStatusKey,
                       taxClass: taxClass,
                       manageStock: manageStock,
                       stockQuantity: quantity,
                       stockStatusKey: stockStatusKey,
                       backordersKey: backordersKey,
                       backordersAllowed: backordersAllowed,
                       backordered: backordered,
                       soldIndividually: soldIndividually,
                       weight: weight,
                       dimensions: createReadOnlyDimensions(),
                       shippingRequired: shippingRequired,
                       shippingTaxable: shippingTaxable,
                       shippingClass: shippingClass,
                       shippingClassID: Int(shippingClassID),
                       reviewsAllowed: reviewsAllowed,
                       averageRating: averageRating,
                       ratingCount: Int(ratingCount),
                       relatedIDs: convertIDArray(relatedIDs),
                       upsellIDs: convertIDArray(upsellIDs),
                       crossSellIDs: convertIDArray(crossSellIDs),
                       parentID: Int(parentID),
                       purchaseNote: purchaseNote,
                       categories: productCategories,
                       tags: productTags,
                       images: productImages,
                       attributes: productAttributes,
                       defaultAttributes: productDefaultAttributes,
                       variations: convertIDArray(variations),
                       groupedProducts: convertIDArray(groupedProducts),
                       menuOrder: Int(menuOrder))
    }

    // MARK: - Private Helpers

    private func createReadOnlyDimensions() -> Yosemite.ProductDimensions {
        guard let dimensions = dimensions else {
            return ProductDimensions(length: "", width: "", height: "")
        }

        return ProductDimensions(length: dimensions.length, width: dimensions.width, height: dimensions.height)
    }

    private func convertIDArray(_ array: [Int64]? ) -> [Int] {
        guard let array = array else {
            return [Int]()
        }

        return array.map { Int($0) }
    }
}
