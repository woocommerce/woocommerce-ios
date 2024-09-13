import Foundation
import Yosemite
import WooFoundation
import protocol Storage.StorageManagerType

/// Provides view data for `WooShippingItems`.
///
final class WooShippingItemsViewModel: ObservableObject {
    private let currencyFormatter: CurrencyFormatter

    /// Data source for items to be shipped.
    private var dataSource: WooShippingItemsDataSource

    /// Label with the total number of items to ship.
    @Published var itemsCountLabel: String = ""

    /// Label with the details of the items to ship.
    @Published var itemsDetailLabel: String = ""

    /// View models for rows of items to ship.
    @Published var itemRows: [WooShippingItemRowViewModel] = []

    init(dataSource: WooShippingItemsDataSource,
         currencySettings: CurrencySettings = ServiceLocator.currencySettings) {
        self.dataSource = dataSource
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
        let itemsCount = dataSource.orderItems.map(\.quantity).reduce(0, +)
        return Localization.itemsCount(itemsCount)
    }

    /// Generates a label with the details of the items to ship.
    /// This includes the total weight and total price of all items.
    ///
    func generateItemsDetailLabel() -> String {
        let formattedWeight = "1 kg" // TODO-13550: Get the total weight (each product/variation * item quantity) and weight unit
        let itemsTotal = dataSource.orderItems.map { $0.price.decimalValue * $0.quantity }.reduce(0, +)
        let formattedPrice = currencyFormatter.formatAmount(itemsTotal) ?? itemsTotal.description

        return "\(formattedWeight) • \(formattedPrice)"
    }

    /// Generates an item row view model for each order item.
    ///
    func generateItemRows() -> [WooShippingItemRowViewModel] {
        dataSource.orderItems.map { item in
            WooShippingItemRowViewModel(imageUrl: nil, // TODO-13550: Get the product/variation imageURL
                                        quantityLabel: item.quantity.description,
                                        name: item.name,
                                        detailsLabel: generateItemRowDetailsLabel(for: item),
                                        weightLabel: "",  // TODO-13550: Get the product/variation weight
                                        priceLabel: currencyFormatter.formatAmount(item.price.decimalValue) ?? item.price.description)
        }
    }

    /// Generates a details label for an item row.
    ///
    func generateItemRowDetailsLabel(for item: OrderItem) -> String {
        let formattedDimensions: String? = nil // TODO-13550: Get the product/variation dimensions

        let attributes: String? = {
            guard item.attributes.isNotEmpty else {
                return nil
            }
            return item.attributes.map { VariationAttributeViewModel(orderItemAttribute: $0) }.map(\.nameOrValue).joined(separator: ", ")
        }()

        return [formattedDimensions, attributes].compacted().joined(separator: " • ")
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
