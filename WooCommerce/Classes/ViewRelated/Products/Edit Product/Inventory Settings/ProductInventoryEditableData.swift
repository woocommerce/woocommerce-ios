import Yosemite

/// Contains editable properties of a product model in the inventory settings.
///
struct ProductInventoryEditableData: Equatable {
    let sku: String?
    let manageStock: Bool
    let soldIndividually: Bool?
    let stockQuantity: Int64?
    let backordersSetting: ProductBackordersSetting?
    let stockStatus: ProductStockStatus?
}

extension ProductInventoryEditableData {
    init(productModel: ProductFormDataModel) {
        self.sku = productModel.sku
        self.manageStock = productModel.manageStock
        self.soldIndividually = (productModel as? Product)?.soldIndividually
        self.stockQuantity = productModel.stockQuantity
        self.backordersSetting = productModel.backordersSetting
        self.stockStatus = productModel.stockStatus
    }
}
