import Foundation
import struct Yosemite.POSSimpleProduct

struct POSStockFormatter {
    static func stockStatusLabel(for product: POSSimpleProduct) -> String {
        switch product.manageStock {
        case false:
            return product.productStockStatus.description
        case true:
            guard let stock = product.stockQuantity else {
                return product.productStockStatus.description
            }
            if stock <= 0 {
                return Localization.outOfStock
            } else {
                return String.localizedStringWithFormat(Localization.inStockWithQuantity, "\(stock)")
            }
        }
    }

    private enum Localization {
        static let outOfStock = NSLocalizedString(
            "pos.stockStatusLabel.outofstock",
            value: "Out of stock",
            comment: "Label to be displayed in the product's card when out of stock")

        static let inStockWithQuantity = NSLocalizedString(
            "pos.stockStatusLabel.inStockWithQuantity",
            value: "%1$@ in stock",
            comment: "Label to be displayed in the product's card when there's stock of a given product")
    }
}
