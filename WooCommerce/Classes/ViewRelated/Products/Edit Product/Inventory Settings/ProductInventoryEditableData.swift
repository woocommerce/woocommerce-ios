import Yosemite

/// Contains editable properties of a Product in the inventory settings.
///
struct ProductInventoryEditableData {
    let sku: String?
    let manageStock: Bool
    let soldIndividually: Bool
    let stockQuantity: Int64?
    let backordersSetting: ProductBackordersSetting?
    let stockStatus: ProductStockStatus?
}

extension ProductInventoryEditableData {
    init(product: Product) {
        self.sku = product.sku
        self.manageStock = product.manageStock
        self.soldIndividually = product.soldIndividually
        self.stockQuantity = product.stockQuantity
        self.backordersSetting = product.backordersSetting
        self.stockStatus = product.productStockStatus
    }
}

extension ProductInventoryEditableData: Equatable {
    static func == (lhs: ProductInventoryEditableData, rhs: ProductInventoryEditableData) -> Bool {
        return lhs.sku == rhs.sku &&
            lhs.manageStock == rhs.manageStock &&
            lhs.soldIndividually == rhs.soldIndividually &&
            lhs.stockQuantity == rhs.stockQuantity &&
            lhs.backordersSetting == rhs.backordersSetting &&
            lhs.stockStatus == rhs.stockStatus
    }
}
