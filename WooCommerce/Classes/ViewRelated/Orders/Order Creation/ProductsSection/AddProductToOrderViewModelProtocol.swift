import Yosemite

/// Represents possible statuses for syncing a list of products or product variations
///
enum AddProductToOrderSyncStatus {
    case firstPageSync
    case results
    case empty
}

/// Protocol for view models for `AddProductToOrder`, to add a product or product variation to an order.
///
protocol AddProductToOrderViewModelProtocol: ObservableObject {
    /// View models for each product row
    ///
    var productRows: [ProductRowViewModel] { get }

    /// Current sync status; used to determine what list view to display.
    ///
    var syncStatus: AddProductToOrderSyncStatus? { get }

    /// Tracks if the infinite scroll indicator should be displayed
    ///
    var shouldShowScrollIndicator: Bool { get }

    /// Select a product or product variation to add to the order
    ///
    func selectProductOrVariation(_ productID: Int64)

    /// Sync first page of products from remote if needed.
    ///
    func syncFirstPage()

    /// Sync next page of products from remote.
    ///
    func syncNextPage()
}

// MARK: - Utils
extension AddProductToOrderViewModelProtocol {
    /// View models of the ghost rows used during the loading process.
    ///
    var ghostRows: [ProductRowViewModel] {
        return Array(0..<6).map { index in
            ProductRowViewModel(product: sampleGhostProduct(id: index), canChangeQuantity: false)
        }
    }

    /// Used for ghost list view while syncing
    ///
    private func sampleGhostProduct(id: Int64) -> Product {
        Product(siteID: 1,
                productID: id,
                name: "Love Ficus",
                slug: "",
                permalink: "",
                date: Date(),
                dateCreated: Date(),
                dateModified: nil,
                dateOnSaleStart: nil,
                dateOnSaleEnd: nil,
                productTypeKey: ProductType.simple.rawValue,
                statusKey: ProductStatus.draft.rawValue,
                featured: false,
                catalogVisibilityKey: ProductCatalogVisibility.hidden.rawValue,
                fullDescription: nil,
                shortDescription: nil,
                sku: "123456",
                price: "20",
                regularPrice: nil,
                salePrice: nil,
                onSale: false,
                purchasable: true,
                totalSales: 0,
                virtual: false,
                downloadable: false,
                downloads: [],
                downloadLimit: -1,
                downloadExpiry: -1,
                buttonText: "",
                externalURL: nil,
                taxStatusKey: ProductTaxStatus.taxable.rawValue,
                taxClass: nil,
                manageStock: false,
                stockQuantity: 7,
                stockStatusKey: ProductStockStatus.inStock.rawValue,
                backordersKey: ProductBackordersSetting.notAllowed.rawValue,
                backordersAllowed: false,
                backordered: false,
                soldIndividually: true,
                weight: nil,
                dimensions: ProductDimensions(length: "1", width: "1", height: "1"),
                shippingRequired: false,
                shippingTaxable: false,
                shippingClass: nil,
                shippingClassID: 0,
                productShippingClass: nil,
                reviewsAllowed: false,
                averageRating: "5",
                ratingCount: 0,
                relatedIDs: [],
                upsellIDs: [],
                crossSellIDs: [],
                parentID: 0,
                purchaseNote: nil,
                categories: [],
                tags: [],
                images: [],
                attributes: [],
                defaultAttributes: [],
                variations: [],
                groupedProducts: [],
                menuOrder: 0,
                addOns: [])
    }
}
