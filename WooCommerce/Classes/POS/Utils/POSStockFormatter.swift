import Foundation
import struct Yosemite.POSSimpleProduct
import struct Yosemite.POSVariation

protocol POSStockManageable {
    var manageStock: Bool { get }
    var stockQuantity: Decimal? { get }
    var stockStatusKey: String { get }
}

extension POSSimpleProduct: POSStockManageable {}
extension POSVariation: POSStockManageable {}

struct POSStockFormatter {
    static func stockStatusLabel(for product: POSStockManageable) -> String {
        switch product.manageStock {
        case false:
            return label(for: product.stockStatusKey)
        case true:
            guard let stock = product.stockQuantity else {
                return label(for: product.stockStatusKey)
            }
            if stock <= 0 {
                return Localization.outOfStock
            } else {
                return String.localizedStringWithFormat(Localization.inStockWithQuantity, "\(stock)")
            }
        }
    }

    private static func label(for key: String) -> String {
        switch key {
        case "instock":
            return Localization.inStock
        case "outofstock":
            return Localization.outOfStock
        case "onbackorder":
            return Localization.onBackOrder
        default:
            return ""
        }
    }

    private enum Localization {
        static let outOfStock = NSLocalizedString(
            "pos.stockStatusLabel.outofstock",
            value: "Out of stock",
            comment: "Label to be displayed in the product's card when out of stock")

        static let inStockWithQuantity = NSLocalizedString(
            "pos.stockStatusLabel.instockwithquantity",
            value: "%1$@ in stock",
            comment: "Label to be displayed in the product's card when there's stock of a given product")

        static let inStock = NSLocalizedString(
            "pos.stockStatusLabel.instock",
            value: "In stock",
            comment: "Label to be displayed in the product's card when in stock")

        static let onBackOrder = NSLocalizedString(
            "pos.stockStatusLabel.onbackorder",
            value: "On back order",
            comment: "Label to be displayed in the product's card when on back order")
    }
}
