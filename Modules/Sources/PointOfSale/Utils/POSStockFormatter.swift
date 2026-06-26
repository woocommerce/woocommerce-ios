import Foundation
import struct Yosemite.POSSimpleProduct
import struct Yosemite.POSVariation

struct POSStockFormatter {
    static func stockStatusLabel(for product: POSSimpleProduct) -> String {
        stockStatusLabel(manageStock: product.manageStock,
                         stockQuantity: product.stockQuantity,
                         productStockStatusDescription: product.productStockStatus.description,
                         pointOfSaleStockQuantity: product.pointOfSaleStockQuantity)
    }

    static func stockStatusLabel(for variation: POSVariation) -> String {
        if let stock = variation.pointOfSaleStockQuantity {
            return stockLabel(for: stock)
        }

        if variation.manageStock {
            return stockStatusLabel(manageStock: variation.manageStock,
                                    stockQuantity: variation.stockQuantity,
                                    productStockStatusDescription: variation.productStockStatus.description,
                                    pointOfSaleStockQuantity: nil)
        }

        if variation.parentPointOfSaleStockQuantity != nil || variation.parentManageStock || !variation.parentStockStatusKey.isEmpty {
            return stockStatusLabel(manageStock: variation.parentManageStock,
                                    stockQuantity: variation.parentStockQuantity,
                                    productStockStatusDescription: variation.parentProductStockStatus.description,
                                    pointOfSaleStockQuantity: variation.parentPointOfSaleStockQuantity)
        }

        return stockStatusLabel(manageStock: variation.manageStock,
                                stockQuantity: variation.stockQuantity,
                                productStockStatusDescription: variation.productStockStatus.description,
                                pointOfSaleStockQuantity: nil)
    }

    private static func stockStatusLabel(manageStock: Bool,
                                         stockQuantity: Decimal?,
                                         productStockStatusDescription: String,
                                         pointOfSaleStockQuantity: Decimal?) -> String {
        if let stock = pointOfSaleStockQuantity {
            return stockLabel(for: stock)
        }

        switch manageStock {
        case false:
            return productStockStatusDescription
        case true:
            guard let stock = stockQuantity else {
                return productStockStatusDescription
            }
            return stockLabel(for: stock)
        }
    }

    private static func stockLabel(for stock: Decimal) -> String {
        if stock <= 0 {
            return Localization.outOfStock
        } else {
            return String.localizedStringWithFormat(Localization.inStockWithQuantity, "\(stock)")
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
