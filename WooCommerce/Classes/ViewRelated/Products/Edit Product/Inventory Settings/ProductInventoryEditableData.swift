import Yosemite

/// Contains editable properties of a product model in the inventory settings.
///
struct ProductInventoryEditableData: Equatable {
    let sku: String?
    let globalUniqueIdentifier: String?
    let manageStock: Bool
    let soldIndividually: Bool?
    let stockQuantity: Decimal?
    let backordersSetting: ProductBackordersSetting?
    let stockStatus: ProductStockStatus?
}

extension ProductInventoryEditableData {
    init(productModel: ProductFormDataModel) {
        self.sku = productModel.sku
        self.globalUniqueIdentifier = productModel.globalUniqueID
        self.manageStock = productModel.manageStock
        self.soldIndividually = productModel.soldIndividually
        self.stockQuantity = productModel.stockQuantity
        self.backordersSetting = productModel.backordersSetting
        self.stockStatus = productModel.stockStatus
    }
}
