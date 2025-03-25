import SwiftUI
import Yosemite
import WooFoundation

/// ViewModel for `WooShippingSplitShipmentsDetailView`
final class WooShippingSplitShipmentsViewModel: ObservableObject {
    private let order: Order
    private let stores: StoresManager
    private let config: WooShippingConfig
    private let currencySettings: CurrencySettings
    private let shippingSettingsService: ShippingSettingsService

    @Published private(set) var shipments: [[CollapsibleShipmentCardViewModel]]

    @Published var selectedShipmentIndex: Int? = 0

    /// Label with the total number of items to ship.
    @Published private(set) var itemsCountLabel: String = ""

    /// Label with the total price for all items in the shipment.
    @Published private(set) var itemsPriceLabel = ""

    /// Label with the total weight for all items in the shipment.
    private var itemsWeightLabel = ""

    /// Label with the details of the items to ship.
    /// Includes total weight and total price for all items in the current shipment.
    var itemsDetailLabel: String {
        "\(itemsWeightLabel) • \(itemsPriceLabel)"
    }

    var topTabItems: [TopTabItem<EmptyView>] {
        shipments.enumerated().map { (index, item) in
            TopTabItem(name: "Shipment \(index + 1)", content: { EmptyView() })
        }
    }

    var currentShipment: [CollapsibleShipmentCardViewModel]? {
        guard let index = selectedShipmentIndex,
            let shipment = shipments[safe: index] else {
            return nil
        }
        return shipment
    }

    @Published var instructionsNotice: Notice?

    init(order: Order,
         config: WooShippingConfig,
         items: [ShippingLabelPackageItem],
         stores: StoresManager = ServiceLocator.stores,
         currencySettings: CurrencySettings = ServiceLocator.currencySettings,
         shippingSettingsService: ShippingSettingsService = ServiceLocator.shippingSettingsService) {
        self.order = order
        self.config = config
        self.stores = stores
        self.currencySettings = currencySettings
        self.shippingSettingsService = shippingSettingsService

        let shipmentCardViewModels = {
            var viewModels = [CollapsibleShipmentCardViewModel]()
            for item in items {
                // TODO: #15303 Set IDs based on web logic
                let childShipmentIds: [String] = {
                    guard item.quantity > 1 else {
                        return []
                    }

                    var children: [String] = []
                    for quantity in 0..<item.quantity.intValue {
                        let childShipmentId = "\(item.productOrVariationID)-sub-\(quantity)"
                        children.append(childShipmentId)
                    }
                    return children
                }()

                let viewModel = CollapsibleShipmentCardViewModel(parentShipmentId: "\(item.productOrVariationID)",
                                                                 childShipmentIds: childShipmentIds,
                                                                 item: item,
                                                                 currency: order.currency)
                viewModels.append(viewModel)
            }
            return viewModels
        }()
        self.shipments = [shipmentCardViewModels]

        configureSectionHeader()
        configureSelectionCallback()
    }

    func onAppear() {
        showInstructionsNotice()
    }

    func selectAll() {
        currentShipment?.forEach {
            $0.selectAll()
        }
    }
}

private extension WooShippingSplitShipmentsViewModel {
    func configureSelectionCallback() {
        currentShipment?.forEach { viewModel in
            viewModel.onSelectionChange = { [weak self] in
                self?.checkSelectionAndHideInstructions()
            }
        }
    }

    func showInstructionsNotice() {
        if hasSelectedAnItem() == false {
            instructionsNotice = Notice(message: Localization.SelectionInstructionsNotice.message,
                                        feedbackType: .success,
                                        actionTitle: Localization.SelectionInstructionsNotice.dismiss) { [weak self] in
                self?.instructionsNotice = nil
            }
        }
    }

    func checkSelectionAndHideInstructions() {
        if hasSelectedAnItem() {
            instructionsNotice = nil
        }
    }

    func hasSelectedAnItem() -> Bool {
        currentShipment?.contains(where: { $0.hasSelectedAnItem }) ?? false
    }

    /// Configures the labels in the section header.
    ///
    func configureSectionHeader() {
        guard let currentShipment else {
            return
        }
        let items = currentShipment.map(\.item)
        let itemsCount = items.map(\.quantity).reduce(0, +)
        itemsCountLabel = Localization.itemsCount(itemsCount)
        itemsWeightLabel = formatWeight(for: items)
        itemsPriceLabel = formatPrice(for: items)
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
        return currencyFormatter.formatAmount(totalPrice, with: order.currency) ?? totalPrice.description
    }
}

// MARK: Constants
private extension WooShippingSplitShipmentsViewModel {
    enum Localization {
        enum SelectionInstructionsNotice {
            static let message = NSLocalizedString("wooShipping.createLabels.splitShipment.SelectionInstructionsNotice.message",
                                                   value: "To split, select the items, and tap **move to new shipment** when the toolbar appears.",
                                                   comment: "Instructions to ask customer to select items to split during shipping label creation."
                                                   + " The content inside two double asterisks **...** denote bolded text.")

            static let dismiss = NSLocalizedString("wooShipping.createLabels.splitShipment.SelectionInstructionsNotice.dismiss",
                                                   value: "Dismiss",
                                                   comment: "Label of the button to dismiss the instructions notice in split shipments flow.")
        }
        static func itemsCount(_ count: Decimal) -> String {
            return String.pluralize(count, singular: Localization.itemsCountSingularFormat, plural: Localization.itemsCountPluralFormat)
        }
        static let itemsCountSingularFormat = NSLocalizedString("wooShipping.createLabels.splitShipment.items.countSingular",
                                                                value: "%1$@ item",
                                                                comment: "Label for singular item to ship during shipping label creation. Reads like: '1 item'")
        static let itemsCountPluralFormat = NSLocalizedString("wooShipping.createLabels.splitShipment.items.count",
                                                              value: "%1$@ items",
                                                              comment: "Label for plural items to ship during shipping label creation. Reads like: '3 items'")
    }
}
