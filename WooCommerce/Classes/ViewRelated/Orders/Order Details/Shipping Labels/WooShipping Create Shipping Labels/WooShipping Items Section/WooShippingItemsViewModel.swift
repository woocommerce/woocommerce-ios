import Foundation
import Yosemite
import WooFoundation
import protocol Storage.StorageManagerType

/// Provides view data for `WooShippingItems`.
///
final class WooShippingItemsViewModel: ObservableObject {
    private let currencyFormatter: CurrencyFormatter
    private let weightFormatter: WeightFormatter
    private let dimensionUnit: String

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
        self.currencyFormatter = CurrencyFormatter(currencySettings: currencySettings)
        self.weightFormatter = WeightFormatter(weightUnit: shippingSettingsService.weightUnit ?? "")
        self.dimensionUnit = shippingSettingsService.dimensionUnit ?? ""

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
        let totalWeight = dataSource.orderItems.map { calculateWeight(for: $0) }.reduce(0, +)
        let formattedWeight = weightFormatter.formatWeight(weight: totalWeight)

        let itemsTotal = dataSource.orderItems.map { $0.price.decimalValue * $0.quantity }.reduce(0, +)
        let formattedPrice = currencyFormatter.formatAmount(itemsTotal) ?? itemsTotal.description

        return "\(formattedWeight) • \(formattedPrice)"
    }

    /// Generates an item row view model for each order item.
    ///
    func generateItemRows() -> [WooShippingItemRowViewModel] {
        dataSource.orderItems.map { item in
            let (product, variation) = getProductAndVariation(for: item)
            let itemWeight = calculateWeight(for: item)
            return WooShippingItemRowViewModel(imageUrl: variation?.imageURL ?? product?.imageURL,
                                               quantityLabel: item.quantity.description,
                                               name: item.name,
                                               detailsLabel: generateItemRowDetailsLabel(for: item),
                                               weightLabel: weightFormatter.formatWeight(weight: itemWeight),
                                               priceLabel: formatPrice(for: item))
        }
    }

    /// Generates a details label for an item row.
    /// Includes item dimensions (height, weight, length) and variation attributes, if available.
    ///
    func generateItemRowDetailsLabel(for item: OrderItem) -> String {
        let dimensions: ProductDimensions? = {
            let (product, productVariation) = getProductAndVariation(for: item)
            if let productVariation {
                return productVariation.dimensions
            } else {
                return product?.dimensions
            }
        }()
        let formattedDimensions: String? = {
            guard let dimensions else {
                return nil
            }
            return String(format: Localization.dimensionsFormat, dimensions.length, dimensions.width, dimensions.height, dimensionUnit)
        }()

        let attributes: String? = {
            guard item.attributes.isNotEmpty else {
                return nil
            }
            return item.attributes.map { VariationAttributeViewModel(orderItemAttribute: $0) }.map(\.nameOrValue).joined(separator: ", ")
        }()

        return [formattedDimensions, attributes].compacted().joined(separator: " • ")
    }

    /// Calculates the weight of the given item based on the item quantity and the product or variation weight.
    ///
    func calculateWeight(for item: OrderItem) -> Double {
        let itemWeight = {
            let (product, productVariation) = getProductAndVariation(for: item)
            if let productVariation {
                return NumberFormatter.double(from: productVariation.weight ?? "") ?? .zero
            } else {
                return NumberFormatter.double(from: product?.weight ?? "") ?? .zero
            }
        }()
        let quantity = Double(truncating: item.quantity as NSDecimalNumber)
        return itemWeight * quantity
    }

    /// Calculates and formats the price of the given item based on the item quantity and unit price.
    ///
    func formatPrice(for item: OrderItem) -> String {
        let totalPrice = item.price.decimalValue * item.quantity
        let formattedPrice = currencyFormatter.formatAmount(totalPrice)
        return formattedPrice ?? item.price.description
    }

    /// Finds the corresponding product and variation for the given item.
    ///
    func getProductAndVariation(for item: OrderItem) -> (Product?, ProductVariation?) {
        let product = dataSource.products.first(where: { $0.productID == item.productID })
        let productVariation = dataSource.productVariations.first(where: { $0.productVariationID == item.variationID })
        return (product, productVariation)
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
