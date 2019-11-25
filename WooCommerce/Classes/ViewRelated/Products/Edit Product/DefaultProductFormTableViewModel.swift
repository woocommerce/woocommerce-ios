import UIKit
import Yosemite

/// The Product form contains 3 sections: images, primary fields, and details.
struct DefaultProductFormTableViewModel: ProductFormTableViewModel {

    private(set) var sections: [ProductFormSection] = []
    private let currency: String
    private let currencyFormatter: CurrencyFormatter

    init(product: Product, currency: String, currencyFormatter: CurrencyFormatter = CurrencyFormatter()) {
        self.currency = currency
        self.currencyFormatter = currencyFormatter
        configureSections(product: product)
    }
}

private extension DefaultProductFormTableViewModel {
    mutating func configureSections(product: Product) {
        sections = [.images,
                    .primaryFields(rows: primaryFieldRows(product: product)),
                    .settings(rows: settingsRows(product: product))]
    }

    func primaryFieldRows(product: Product) -> [ProductFormSection.PrimaryFieldRow] {
        return [
            .name(name: product.name),
            .description(description: product.trimmedFullDescription)
        ]
    }

    func settingsRows(product: Product) -> [ProductFormSection.SettingsRow] {
        return [
            .price(viewModel: priceSettingsRow(product: product)),
            .shipping(viewModel: shippingSettingsRow(product: product)),
            .inventory(viewModel: inventorySettingsRow(product: product))
        ]
    }
}

private extension DefaultProductFormTableViewModel {
    func priceSettingsRow(product: Product) -> ProductFormSection.SettingsRow.ViewModel {
        let icon = UIImage.priceImage.applyProductFormSettingsStyle()
        let title = Constants.priceSettingsTitle

        var priceDetails = [String]()

        // Regular price and sale price are both available only when a sale price is set.
        if let regularPrice = product.regularPrice, !regularPrice.isEmpty,
            let salePrice = product.salePrice, !salePrice.isEmpty {
            let formattedRegularPrice = currencyFormatter.formatAmount(regularPrice, with: currency) ?? ""
            let formattedSalePrice = currencyFormatter.formatAmount(salePrice, with: currency) ?? ""
            priceDetails.append(String.localizedStringWithFormat(Constants.regularPriceFormat, formattedRegularPrice))
            priceDetails.append(String.localizedStringWithFormat(Constants.salePriceFormat, formattedSalePrice))

            // TODO-1505: show sale period
        } else if product.price.isEmpty == false {
            let formattedPrice = currencyFormatter.formatAmount(product.price, with: currency) ?? ""
            priceDetails.append(String.localizedStringWithFormat(Constants.regularPriceFormat, formattedPrice))
        }

        let details = priceDetails.isEmpty ? nil: priceDetails.joined(separator: "\n")
        return ProductFormSection.SettingsRow.ViewModel(icon: icon,
                                                        title: title,
                                                        details: details)
    }

    func inventorySettingsRow(product: Product) -> ProductFormSection.SettingsRow.ViewModel {
        let icon = UIImage.inventoryImage.applyProductFormSettingsStyle()
        let title = Constants.inventorySettingsTitle

        var inventoryDetails = [String]()

        if let sku = product.sku, !sku.isEmpty {
            inventoryDetails.append(String.localizedStringWithFormat(Constants.skuFormat, sku))
        }

        if let stockQuantity = product.stockQuantity {
            inventoryDetails.append(String.localizedStringWithFormat(Constants.stockQuantityFormat, stockQuantity))
        } else {
            let stockStatus = product.productStockStatus
            inventoryDetails.append(String.localizedStringWithFormat(Constants.stockStatusFormat, stockStatus.description))
        }

        let details = inventoryDetails.isEmpty ? nil: inventoryDetails.joined(separator: "\n")

        return ProductFormSection.SettingsRow.ViewModel(icon: icon,
                                                        title: title,
                                                        details: details)
    }

    func shippingSettingsRow(product: Product) -> ProductFormSection.SettingsRow.ViewModel {
        let icon = UIImage.shippingImage.applyProductFormSettingsStyle()
        let title = Constants.shippingSettingsTitle
        // TODO-1507: show shipping details after the weight and dimension units are available
        let details: String? = nil
        return ProductFormSection.SettingsRow.ViewModel(icon: icon,
                                                        title: title,
                                                        details: details)
    }
}

private extension DefaultProductFormTableViewModel {
    enum Constants {
        static let priceSettingsTitle = NSLocalizedString("Price",
                                                          comment: "Title of the Price Settings row on Product main screen")
        static let inventorySettingsTitle = NSLocalizedString("Inventory",
                                                              comment: "Title of the Inventory Settings row on Product main screen")
        static let shippingSettingsTitle = NSLocalizedString("Shipping",
                                                             comment: "Title of the Shipping Settings row on Product main screen")

        // Price
        static let regularPriceFormat = NSLocalizedString("Regular price: %@",
                                                          comment: "Format of the regular price on the Price Settings row")
        static let salePriceFormat = NSLocalizedString("Sale price: %@",
                                                       comment: "Format of the sale price on the Price Settings row")
        static let saleDatesFormat = NSLocalizedString("Sale dates: %1$@-%2$@",
                                                       comment: "Format of the sale period on the Price Settings row")

        // Inventory
        static let skuFormat = NSLocalizedString("SKU: %@",
                                                 comment: "Format of the SKU on the Inventory Settings row")
        static let stockQuantityFormat = NSLocalizedString("Quantity: %ld",
                                                           comment: "Format of the stock quantity on the Inventory Settings row")
        static let stockStatusFormat = NSLocalizedString("Stock status: %@",
                                                         comment: "Format of the stock status on the Inventory Settings row")
    }
}
