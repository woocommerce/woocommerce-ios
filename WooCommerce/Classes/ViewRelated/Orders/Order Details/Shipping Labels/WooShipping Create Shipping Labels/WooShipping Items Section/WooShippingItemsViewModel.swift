import Foundation
import Yosemite
import WooFoundation

/// Provides view data for `WooShippingItems`.
///
final class WooShippingItemsViewModel: ObservableObject {
    private let order: Order
    private let currencyFormatter: CurrencyFormatter

    /// Label with the total number of items to ship.
    @Published var itemsCountLabel: String = ""

    /// Label with the details of the items to ship.
    @Published var itemsDetailLabel: String = ""

    /// View models for rows of items to ship.
    @Published var itemRows: [WooShippingItemRowViewModel] = []

    init(order: Order,
         currencySettings: CurrencySettings = ServiceLocator.currencySettings) {
        self.order = order
        self.currencyFormatter = CurrencyFormatter(currencySettings: currencySettings)

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
        itemRows = generateItemRows()
    }

    /// Generates a label with the total number of items to ship.
    ///
    func generateItemsCountLabel() -> String {
        let itemsCount = order.items
            .map { $0.quantity }
            .reduce(0, +)
        return Localization.itemsCount(itemsCount)
    }

    /// Generates a label with the details of the items to ship.
    /// This includes the total weight and total price of all items.
    ///
    func generateItemsDetailLabel() -> String {
        let formattedWeight = "1 kg" // TODO-13550: Get the total weight (each product/variation * item quantity) and weight unit
        let formattedPrice = currencyFormatter.formatAmount(order.total) ?? order.total

        return "\(formattedWeight) • \(formattedPrice)"
    }

    /// Generates an item row view model for each order item.
    ///
    func generateItemRows() -> [WooShippingItemRowViewModel] {
        order.items.map { item in
            return WooShippingItemRowViewModel(imageUrl: nil, // TODO-13550: Get the product/variation imageURL
                                               quantityLabel: item.quantity.description,
                                               name: item.name,
                                               detailsLabel: "", // TODO-13550: Get the product details
                                               weightLabel: "",  // TODO-13550: Get the product/variation weight
                                               priceLabel: currencyFormatter.formatAmount(item.total) ?? item.total)
        }
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
                                                        comment: "Total number of items to ship during shipping label creation.")
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
