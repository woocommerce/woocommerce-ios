import Foundation
import Storage

extension Storage.Product {
    var imagesArray: [Storage.ProductImage] {
        return images?.toArray() ?? []
    }
    var tagsArray: [Storage.ProductTag] {
        return tags?.toArray() ?? []
    }
    var downloadableFilesArray: [Storage.ProductDownload] {
        return downloads?.toArray() ?? []
    }
}

// MARK: - Storage.Product: ReadOnlyConvertible
//
extension Storage.Product: ReadOnlyConvertible {

    /// Updates the Storage.Product with the ReadOnly.
    ///
    public func update(with product: Yosemite.Product) {
        siteID = product.siteID
        productID = product.productID
        productTypeKey = product.productTypeKey
        name = product.name
        slug = product.slug
        permalink = product.permalink
        date = product.date
        dateCreated = product.dateCreated
        dateModified = product.dateModified
        dateOnSaleStart = product.dateOnSaleStart
        dateOnSaleEnd = product.dateOnSaleEnd
        statusKey = product.statusKey
        featured = product.featured
        catalogVisibilityKey = product.catalogVisibilityKey
        fullDescription = product.fullDescription
        briefDescription = product.shortDescription
        sku = product.sku
        price = product.price
        regularPrice = product.regularPrice
        salePrice = product.salePrice
        onSale = product.onSale
        purchasable = product.purchasable
        totalSales = Int64(product.totalSales)
        virtual = product.virtual
        downloadable = product.downloadable
        downloadLimit = product.downloadLimit
        downloadExpiry = product.downloadExpiry
        buttonText = product.buttonText
        externalURL = product.externalURL
        taxStatusKey = product.taxStatusKey
        taxClass = product.taxClass
        manageStock = product.manageStock

        var quantity: String? = nil
        if let stockQuantity = product.stockQuantity {
            quantity = stockQuantity.description
        }
        stockQuantity = quantity

        stockStatusKey = product.stockStatusKey
        soldIndividually = product.soldIndividually
        weight = product.weight
        shippingRequired = product.shippingRequired
        shippingTaxable = product.shippingTaxable
        shippingClass = product.shippingClass
        shippingClassID = product.shippingClassID
        reviewsAllowed = product.reviewsAllowed
        averageRating = product.averageRating
        ratingCount = Int64(product.ratingCount)
        relatedIDs = product.relatedIDs
        upsellIDs = product.upsellIDs
        crossSellIDs = product.crossSellIDs
        parentID = product.parentID
        purchaseNote = product.purchaseNote
        variations = product.variations
        groupedProducts = product.groupedProducts
        menuOrder = Int64(product.menuOrder)
        backordersKey = product.backordersKey
        backordersAllowed = product.backordersAllowed
        backordered = product.backordered
    }

    /// Returns a ReadOnly version of the receiver.
    ///
    public func toReadOnly() -> Yosemite.Product {

        let productCategories = categories?.map { $0.toReadOnly() } ?? [Yosemite.ProductCategory]()
        let productDownloads = downloadableFilesArray.map { $0.toReadOnly() }
        let productTags = tagsArray.map { $0.toReadOnly() }
        let productImages = imagesArray.map { $0.toReadOnly() }
        let productAttributes = attributes?.map { $0.toReadOnly() } ?? [Yosemite.ProductAttribute]()
        let productDefaultAttributes = defaultAttributes?.map { $0.toReadOnly() } ?? [Yosemite.ProductDefaultAttribute]()
        let productShippingClassModel = productShippingClass?.toReadOnly()

        var quantity: Decimal?
        if let stockQuantity = stockQuantity {
            quantity = Decimal(string: stockQuantity)
        }

        return Product(siteID: siteID,
                       productID: productID,
                       name: name,
                       slug: slug,
                       permalink: permalink,
                       date: date,
                       dateCreated: dateCreated,
                       dateModified: dateModified,
                       dateOnSaleStart: dateOnSaleStart,
                       dateOnSaleEnd: dateOnSaleEnd,
                       productTypeKey: productTypeKey,
                       statusKey: statusKey,
                       featured: featured,
                       catalogVisibilityKey: catalogVisibilityKey,
                       fullDescription: fullDescription,
                       shortDescription: briefDescription,
                       sku: sku,
                       price: price,
                       regularPrice: regularPrice,
                       salePrice: salePrice,
                       onSale: onSale,
                       purchasable: purchasable,
                       totalSales: Int(totalSales),
                       virtual: virtual,
                       downloadable: downloadable,
                       downloads: productDownloads,
                       downloadLimit: downloadLimit,
                       downloadExpiry: downloadExpiry,
                       buttonText: buttonText,
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
                       shippingClassID: shippingClassID,
                       productShippingClass: productShippingClassModel,
                       reviewsAllowed: reviewsAllowed,
                       averageRating: averageRating,
                       ratingCount: Int(ratingCount),
                       relatedIDs: convertIDArray(relatedIDs),
                       upsellIDs: convertIDArray(upsellIDs),
                       crossSellIDs: convertIDArray(crossSellIDs),
                       parentID: parentID,
                       purchaseNote: purchaseNote,
                       categories: productCategories.sorted(),
                       tags: productTags,
                       images: productImages,
                       attributes: productAttributes.sorted(),
                       defaultAttributes: productDefaultAttributes.sorted(),
                       variations: variations ?? [],
                       groupedProducts: groupedProducts ?? [],
                       menuOrder: Int(menuOrder))
    }

    // MARK: - Private Helpers

    private func createReadOnlyDimensions() -> Yosemite.ProductDimensions {
        guard let dimensions = dimensions else {
            return ProductDimensions(length: "", width: "", height: "")
        }

        return ProductDimensions(length: dimensions.length, width: dimensions.width, height: dimensions.height)
    }

    private func convertIDArray(_ array: [Int64]? ) -> [Int64] {
        guard let array = array else {
            return [Int64]()
        }

        return array.map { Int64($0) }
    }
}
