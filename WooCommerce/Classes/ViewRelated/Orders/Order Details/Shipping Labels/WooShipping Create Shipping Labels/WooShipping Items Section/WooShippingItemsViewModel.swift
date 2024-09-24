import Foundation
import Yosemite
import WooFoundation
import protocol Storage.StorageManagerType

/// Provides view data for `WooShippingItems`.
///
final class WooShippingItemsViewModel: ObservableObject {
    private let shippingSettingsService: ShippingSettingsService
    private let currencySettings: CurrencySettings

    /// Data source for items to be shipped.
    private var dataSource: WooShippingItemsDataSource

    /// Label with the total number of items to ship.
    @Published var itemsCountLabel: String = ""

    /// Label with the details of the items to ship.
    /// Include total weight and total price for all items in the shipment.
    @Published var itemsDetailLabel: String = ""

    /// View models for rows of items to ship.
    @Published var itemRows: [WooShippingItemRowViewModel] = []

    init(dataSource: WooShippingItemsDataSource,
         currencySettings: CurrencySettings = ServiceLocator.currencySettings,
         shippingSettingsService: ShippingSettingsService = ServiceLocator.shippingSettingsService) {
        self.dataSource = dataSource
        self.currencySettings = currencySettings
        self.shippingSettingsService = shippingSettingsService

        configureSectionHeader()
        configureItemRows()
    }
}

private extension WooShippingItemsViewModel {
    /// Configures the labels in the section header.
    ///
    func configureSectionHeader() {
        itemsCountLabel = generateItemsCountLabel()
        itemsDetailLabel = generateItemsDetailLabel()
    }

    /// Configures the item rows.
    ///
    func configureItemRows() {
        itemRows = dataSource.items.map { item in
            WooShippingItemRowViewModel(item: item)
        }
    }

    /// Generates a label with the total number of items to ship.
    ///
    func generateItemsCountLabel() -> String {
        let itemsCount = dataSource.items.map(\.quantity).reduce(0, +)
        return Localization.itemsCount(itemsCount)
    }

    /// Generates a label with the details of the items to ship.
    /// This includes the total weight and total price of all items.
    ///
    func generateItemsDetailLabel() -> String {
        let formattedWeight = formatWeight(for: dataSource.items)
        let formattedPrice = formatPrice(for: dataSource.items)
        return "\(formattedWeight) • \(formattedPrice)"
    }

    /// Calculates and formats the total weight of the given items based on each item's weight and quantity.
    ///
    func formatWeight(for items: [ShippingLabelPackageItem]) -> String {
        let totalWeight = items
            .map { item in
                item.weight * Double(truncating: item.quantity as NSDecimalNumber)
            }
            .reduce(0, +)
        let weightFormatter = WeightFormatter(weightUnit: shippingSettingsService.weightUnit ?? "")
        return weightFormatter.formatWeight(weight: totalWeight)
    }

    /// Calculates and formats the price of the given item based on the item quantity and unit price.
    ///
    func formatPrice(for items: [ShippingLabelPackageItem]) -> String {
        let totalPrice = items.map { Decimal($0.value) * $0.quantity }.reduce(0, +)
        let currencyFormatter = CurrencyFormatter(currencySettings: currencySettings)
        return currencyFormatter.formatAmount(totalPrice) ?? totalPrice.description
    }
}

// MARK: Constants
private extension WooShippingItemsViewModel {
    enum Localization {
        static func itemsCount(_ count: Decimal) -> String {
            let formattedCount = NumberFormatter.localizedString(from: count as NSDecimalNumber, number: .decimal)
            return String(format: Localization.itemsCountFormat, formattedCount)
        }
        static let itemsCountFormat = NSLocalizedString("wooShipping.createLabels.items.count",
                                                        value: "%1$@ items",
                                                        comment: "Total number of items to ship during shipping label creation. Reads like: '3 items'")
        static let dimensionsFormat = NSLocalizedString("wooShipping.createLabels.items.dimensions",
                                                        value: "%1$@ x %2$@ x %3$@ %4$@",
                                                        comment: "Length, width, and height dimensions with the unit for an item to ship. "
                                                        + "Reads like: '20 x 35 x 5 cm'")
    }
}

/// Convenience extension to provide data to `WooShippingItemRow`
extension WooShippingItems {
    init(viewModel: WooShippingItemsViewModel) {
        self.itemsCountLabel = viewModel.itemsCountLabel
        self.itemsDetailLabel = viewModel.itemsDetailLabel
        self.items = viewModel.itemRows
    }
}
