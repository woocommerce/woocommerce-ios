import Codegen
import Foundation
import Yosemite

/// Represents a Product Entity with basic details to display in the product list of Products tab.
///
struct ProductListItem: Equatable, GeneratedCopiable {
    let siteID: Int64
    let productID: Int64
    let name: String

    let productTypeKey: String
    let statusKey: String        // draft, pending, private, published
    let sku: String?

    let manageStock: Bool
    let stockQuantity: Decimal?    // Core API reports Int or null; some extensions allow decimal values as well
    let stockStatusKey: String   // instock, outofstock, backorder

    let imageURL: URL?

    let variations: [Int64]

    // MARK: Product Bundle properties

    /// Stock status of this bundle, taking bundled product quantity requirements and limitations into account. Applicable for bundle-type products only.
    let bundleStockStatus: ProductStockStatus?

    /// Quantity of bundles left in stock, taking bundled product quantity requirements into account. Applicable for bundle-type products only.
    let bundleStockQuantity: Int64?

    /// Computed Properties
    ///
    var productStatus: ProductStatus {
        return ProductStatus(rawValue: statusKey)
    }
    var productStockStatus: ProductStockStatus {
        return ProductStockStatus(rawValue: stockStatusKey)
    }
    var productType: ProductType {
        return ProductType(rawValue: productTypeKey)
    }
    /// Product struct initializer.
    ///
    init(siteID: Int64,
         productID: Int64,
         name: String,
         productTypeKey: String,
         statusKey: String,
         sku: String?,
         manageStock: Bool,
         stockQuantity: Decimal?,
         stockStatusKey: String,
         imageURL: URL?,
         variations: [Int64],
         bundleStockStatus: ProductStockStatus?,
         bundleStockQuantity: Int64?) {
        self.siteID = siteID
        self.productID = productID
        self.name = name
        self.productTypeKey = productTypeKey
        self.statusKey = statusKey
        self.sku = sku
        self.manageStock = manageStock
        self.stockQuantity = stockQuantity
        self.stockStatusKey = stockStatusKey
        self.imageURL = imageURL
        self.variations = variations
        self.bundleStockStatus = bundleStockStatus
        self.bundleStockQuantity = bundleStockQuantity
    }

    init(storageProduct: StorageProduct) {
        self.siteID = storageProduct.siteID
        self.productID = storageProduct.productID
        self.name = storageProduct.name
        self.productTypeKey = storageProduct.productTypeKey
        self.statusKey = storageProduct.statusKey
        self.sku = storageProduct.sku
        self.manageStock = storageProduct.manageStock
        self.stockQuantity = {
            var quantity: Decimal?
            if let stockQuantity = storageProduct.stockQuantity {
                quantity = Decimal(string: stockQuantity)
            }
            return quantity
        }()
        self.stockStatusKey = storageProduct.stockStatusKey
        self.imageURL = storageProduct.imagesArray.first?.toReadOnly().imageURL
        self.variations = storageProduct.variations ?? []
        self.bundleStockStatus = {
            var productBundleStockStatus: ProductStockStatus?
            if let bundleStockStatus = storageProduct.bundleStockStatus {
                productBundleStockStatus = ProductStockStatus(rawValue: bundleStockStatus)
            }
            return productBundleStockStatus
        }()
        self.bundleStockQuantity = storageProduct.bundleStockQuantity as? Int64
    }
}

extension ProductListItem: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(siteID)
        hasher.combine(productID)
    }
}
