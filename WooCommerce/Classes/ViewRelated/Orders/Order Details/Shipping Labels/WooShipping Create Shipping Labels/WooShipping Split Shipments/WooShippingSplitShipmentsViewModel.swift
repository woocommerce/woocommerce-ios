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

    typealias Shipment = [CollapsibleShipmentItemCardViewModel]

    @Published private(set) var shipments: [Shipment]

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
            TopTabItem(name: String.localizedStringWithFormat(Localization.shipmentFormat, index + 1),
                       content: { EmptyView() })
        }
    }

    var currentShipment: [CollapsibleShipmentItemCardViewModel] {
        let index = selectedShipmentIndex ?? 0
        return shipments[index]
    }

    @Published private(set) var moveToNoticeViewModel: MoveToShipmentNoticeViewModel?

    @Published private(set) var instructions: String?
    private var dismissedInstructions: Bool = false


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

        let initialShipment = items.map { item in
            CollapsibleShipmentItemCardViewModel(item: item, currency: order.currency)
        }
        self.shipments = [initialShipment]

        configureSectionHeader()
        configureSelectionCallback()
    }

    func onAppear() {
        showInstructionsNotice()
        showMoveToNotice()
    }

    func selectAll() {
        currentShipment.forEach {
            $0.selectAll()
        }
    }

    func dismissInstructions() {
        instructions = nil
        dismissedInstructions = true
    }
}

private extension WooShippingSplitShipmentsViewModel {
    func configureSelectionCallback() {
        currentShipment.forEach { viewModel in
            viewModel.onSelectionChange = { [weak self] in
                self?.showMoveToNotice()
            }
        }
    }

    func showInstructionsNotice() {
        if !dismissedInstructions {
            instructions = Localization.SelectionInstructionsNotice.message
        }
    }

    func showMoveToNotice() {
        let shipmentIndex = selectedShipmentIndex ?? 0
        let selectedItemsCount = currentShipment
            .map(\.numberOfSelectedItems)
            .reduce(0, +)

        guard selectedItemsCount > 0 else {
            return moveToNoticeViewModel = nil
        }

        moveToNoticeViewModel = MoveToShipmentNoticeViewModel(selectedItemsCount: selectedItemsCount,
                                                              existingShipmentsCount: shipments.count,
                                                              currentShipmentIndex: shipmentIndex,
                                                              actionHandler: { [weak self] moveTo in
            guard let self else { return }

            moveToNoticeViewModel = nil
            instructions = nil

            switch moveTo {
            case .existingShipment:
                break
            case .newShipment:
                break
            }
        })
    }

    /// Configures the labels in the section header.
    ///
    func configureSectionHeader() {
        let items = currentShipment.map(\.packageItem)
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
        static let shipmentFormat = NSLocalizedString(
            "wooShipping.createLabels.splitShipment.shipmentFormat",
            value: "Shipment %1$d",
            comment: "Label for a shipment during shipping label creation. The placeholder is the index of the shipment. Reads like: 'Shipment 1'"
        )
    }
}
