import struct Yosemite.POSSimpleProduct

struct StockFormatter {
    static func stockStatusLabel(for product: POSSimpleProduct) -> String {
        switch product.manageStock {
        case false:
            return product.productStockStatus.description
        case true:
            guard let stock = product.stockQuantity else {
                return product.productStockStatus.description
            }
            if stock <= 0 {
                return "Out of stock"
            } else {
                return "\(stock) in stock"
            }
        }
    }
}
