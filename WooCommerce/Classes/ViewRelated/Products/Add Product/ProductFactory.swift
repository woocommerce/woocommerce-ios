import Yosemite

/// Creates a new product given a set of parameters.
///
struct ProductFactory {
    /// Creates a new product (does not exist remotely) for a site ID of a given type.
    ///
    /// - Parameters:
    ///   - type: The type of the product.
    ///   - isVirtual: Whether the product is virtual (for simple products).
    ///   - siteID: The site ID where the product is added to.
    ///   - status: The status of the new product.
    func createNewProduct(type: ProductType, isVirtual: Bool, siteID: Int64) -> Product? {
        switch type {
        case .simple, .grouped, .variable, .affiliate, .subscription, .variableSubscription:
            return createEmptyProduct(type: type, isVirtual: isVirtual, siteID: siteID)
        default:
            return nil
        }
    }

    /// Copies a product by cleaning properties like `id, name, statusKey, and groupedProducts` to their default state.
    /// This is useful to turn an existing (on core) `auto-draft` product into a new app-product ready to be saved.
    ///
    /// - Parameters:
    ///   - existingProduct: The product to copy.
    ///   - status: The status of the new product.
    func newProduct(from existingProduct: Product) -> Product {
        return existingProduct.copy(productID: 0, name: "", statusKey: ProductStatus.published.rawValue, groupedProducts: [])
    }
}

private extension ProductFactory {
    func createEmptyProduct(type: ProductType, isVirtual: Bool, siteID: Int64) -> Product {
        Product(siteID: siteID,
                productID: 0,
                name: "",
                slug: "",
                permalink: "",
                date: Date(),
                dateCreated: Date(),
                dateModified: nil,
                dateOnSaleStart: nil,
                dateOnSaleEnd: nil,
                productTypeKey: type.rawValue,
                statusKey: ProductStatus.published.rawValue,
                featured: false,
                catalogVisibilityKey: ProductCatalogVisibility.visible.rawValue,
                fullDescription: "",
                shortDescription: "",
                sku: "",
                price: "",
                regularPrice: "",
                salePrice: "",
                onSale: false,
                purchasable: false,
                totalSales: 0,
                virtual: isVirtual,
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
                menuOrder: 0,
                addOns: [],
                isSampleItem: false,
                bundleStockStatus: nil,
                bundleStockQuantity: nil,
                bundleMinSize: nil,
                bundleMaxSize: nil,
                bundledItems: [],
                password: nil,
                compositeComponents: [],
                subscription: type == .subscription ? .empty : nil,
                minAllowedQuantity: nil,
                maxAllowedQuantity: nil,
                groupOfQuantity: nil,
                combineVariationQuantities: nil)
    }
}
