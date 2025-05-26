import struct Yosemite.POSSimpleProduct

struct StockFormatter {
    static func stockStatusLabel(for product: POSSimpleProduct) -> String {
        switch product.manageStock {
        case false:
            return product.productStockStatus.description
        case true:
            // TODO: Needs additional handling to show the number of items in stock.
            return product.productStockStatus.description
        }
    }
}
