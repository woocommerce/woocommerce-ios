import Yosemite

/// Creates a new product given a set of parameters.
///
struct ProductFactory {
    /// Creates a new product (does not exist remotely) for a site ID of a given type.
    ///
    /// - Parameters:
    ///   - type: The type of the product.
    ///   - siteID: The site ID where the product is added to.
    func createNewProduct(type: ProductType, siteID: Int64) -> Product? {
        switch type {
        case .simple, .grouped, .variable, .affiliate:
            return createEmptyProduct(type: type, siteID: siteID)
        default:
            return nil
        }
    }
}

private extension ProductFactory {
    func createEmptyProduct(type: ProductType, siteID: Int64) -> Product {
        Product(siteID: siteID,
                productID: 0,
                name: "",
                slug: "",
                permalink: "",
                dateCreated: Date(),
                dateModified: nil,
                dateOnSaleStart: nil,
                dateOnSaleEnd: nil,
                productTypeKey: type.rawValue,
                statusKey: ProductStatus.publish.rawValue,
                featured: false,
                catalogVisibilityKey: ProductCatalogVisibility.visible.rawValue,
                fullDescription: "",
                briefDescription: "",
                sku: "",
                price: "",
                regularPrice: "",
                salePrice: "",
                onSale: false,
                purchasable: false,
                totalSales: 0,
                virtual: false,
                downloadable: false,
                downloads: [],
                downloadLimit: -1,
                downloadExpiry: -1,
                buttonText: "",
                externalURL: "",
                taxStatusKey: ProductTaxStatus.taxable.rawValue,
                taxClass: "",
                manageStock: false,
                stockQuantity: nil,
                stockStatusKey: ProductStockStatus.inStock.rawValue,
                backordersKey: ProductBackordersSetting.notAllowed.rawValue,
                backordersAllowed: false,
                backordered: false,
                soldIndividually: false,
                weight: "",
                dimensions: ProductDimensions(length: "", width: "", height: ""),
                shippingRequired: true,
                shippingTaxable: true,
                shippingClass: "",
                shippingClassID: 0,
                productShippingClass: nil,
                reviewsAllowed: true,
                averageRating: "",
                ratingCount: 0,
                relatedIDs: [],
                upsellIDs: [],
                crossSellIDs: [],
                parentID: 0,
                purchaseNote: "",
                categories: [],
                tags: [],
                images: [],
                attributes: [],
                defaultAttributes: [],
                variations: [],
                groupedProducts: [],
                menuOrder: 0)
    }
}
