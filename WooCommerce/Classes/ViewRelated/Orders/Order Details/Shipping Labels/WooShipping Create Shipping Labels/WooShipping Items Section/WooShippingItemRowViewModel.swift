import Foundation
import protocol Yosemite.ShippingSettingsService
import WooFoundation

/// Provides view data for `WooShippingItemRow`.
///
struct WooShippingItemRowViewModel: Identifiable {
    /// Unique ID for the item row
    let id = UUID()

    /// URL for item image
    let imageUrl: URL?

    /// Label for item quantity
    let quantityLabel: String

    /// Item name
    let name: String

    /// Label for item details
    let detailsLabel: String

    /// Label for item weight
    let weightLabel: String

    /// Label for item price
    let priceLabel: String

    init(imageUrl: URL?,
         quantityLabel: String,
         name: String,
         detailsLabel: String,
         weightLabel: String,
         priceLabel: String) {
        self.imageUrl = imageUrl
        self.quantityLabel = quantityLabel
        self.name = name
        self.detailsLabel = detailsLabel
        self.weightLabel = weightLabel
        self.priceLabel = priceLabel
    }

    init(item: ShippingLabelPackageItem,
         shippingSettingsService: ShippingSettingsService = ServiceLocator.shippingSettingsService,
         currencySettings: CurrencySettings = ServiceLocator.currencySettings) {
        self.imageUrl = item.imageURL
        self.quantityLabel = item.quantity.description
        self.name = item.name

        let dimensionUnit = shippingSettingsService.dimensionUnit ?? ""
        self.detailsLabel = [item.formatDimensions(with: dimensionUnit), item.formattedAttributes].compacted().joined(separator: " • ")

        let weightUnit = shippingSettingsService.weightUnit ?? ""
        self.weightLabel = item.formatWeight(with: weightUnit)

        self.priceLabel = item.formatPrice(with: currencySettings)
    }
}

// MARK: Formatting helpers
private extension ShippingLabelPackageItem {
    /// Provides the item attributes formatted in a comma-separated list.
    ///
    var formattedAttributes: String? {
        guard attributes.isNotEmpty else {
            return nil
        }
        return attributes.map(\.nameOrValue).joined(separator: ", ")
    }

    /// Formats the item dimensions with the provided dimension unit.
    ///
    func formatDimensions(with unit: String) -> String {
        String(format: Localization.dimensionsFormat, dimensions.length, dimensions.width, dimensions.height, unit)
    }

    /// Formats the total item weight (per-unit weight x quantity) with the provided weight unit.
    ///
    func formatWeight(with unit: String) -> String {
        let weightFormatter = WeightFormatter(weightUnit: unit)
        let totalWeight = weight * Double(truncating: quantity as NSDecimalNumber)
        return weightFormatter.formatWeight(weight: totalWeight)
    }

    /// Formats the total item price (per-unit value x quantity) with the provided currency settings.
    ///
    func formatPrice(with settings: CurrencySettings) -> String {
        let totalPrice = Decimal(value) * quantity
        let currencyFormatter = CurrencyFormatter(currencySettings: settings)
        return currencyFormatter.formatAmount(totalPrice) ?? totalPrice.description
    }

    enum Localization {
        static let dimensionsFormat = NSLocalizedString("wooShipping.createLabels.items.dimensions",
                                                        value: "%1$@ x %2$@ x %3$@ %4$@",
                                                        comment: "Length, width, and height dimensions with the unit for an item to ship. "
                                                        + "Reads like: '20 x 35 x 5 cm'")
    }
}

/// Convenience extension to provide data to `WooShippingItemRow`
extension WooShippingItemRow {
    init(viewModel: WooShippingItemRowViewModel) {
        self.imageUrl = viewModel.imageUrl
        self.quantityLabel = viewModel.quantityLabel
        self.name = viewModel.name
        self.detailsLabel = viewModel.detailsLabel
        self.weightLabel = viewModel.weightLabel
        self.priceLabel = viewModel.priceLabel
    }
}
