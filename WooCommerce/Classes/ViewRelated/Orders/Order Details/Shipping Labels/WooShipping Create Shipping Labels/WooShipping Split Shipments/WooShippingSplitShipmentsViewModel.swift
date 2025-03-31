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

    @Published var selectedShipmentIndex = 0 {
        didSet {
            configureSectionHeader()
            configureSelectionCallback()
            updateMoveToNotice()
        }
    }

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
        shipments[selectedShipmentIndex]
    }

    @Published private(set) var moveToNoticeViewModel: MoveToShipmentNoticeViewModel?

    @Published private(set) var instructions: AttributedString?
    private var dismissedInstructions: Bool = false

    @Published private(set) var movingCompletionMessage: AttributedString?
    private var undoMovingItemsHandler: (() -> Void)?

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
        updateMoveToNotice()
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

    func moveSelectedItems(to destination: MoveToShipmentNoticeViewModel.Destination) {
        moveToNoticeViewModel = nil
        instructions = nil

        // Step 0: keep the details before changes to revert changes when undo is selected
        let initialShipments = shipments
        let currentIndex = selectedShipmentIndex
        undoMovingItemsHandler = { [weak self] in
            guard let self else { return }
            shipments = initialShipments
            selectedShipmentIndex = currentIndex
        }

        // Step 1: Split items
        var newShipment = Shipment()
        var movedItems = [CollapsibleShipmentItemCardViewModel]()
        for item in currentShipment {
            let initialQuantity = item.packageItem.quantity.intValue
            let selectedQuantity = item.numberOfSelectedItems
            let remainingQuantity = initialQuantity - selectedQuantity
            if remainingQuantity == 0 {
                movedItems.append(
                    CollapsibleShipmentItemCardViewModel(item: item.packageItem, currency: order.currency)
                )
            } else if selectedQuantity > 0 {
                let newItem = ShippingLabelPackageItem(copy: item.packageItem, quantity: Decimal(remainingQuantity))
                newShipment.append(
                    CollapsibleShipmentItemCardViewModel(item: newItem, currency: order.currency)
                )
                let movedItem = ShippingLabelPackageItem(copy: item.packageItem, quantity: Decimal(selectedQuantity))
                movedItems.append(
                    CollapsibleShipmentItemCardViewModel(item: movedItem, currency: order.currency)
                )
            } else if selectedQuantity == 0 {
                newShipment.append(
                    CollapsibleShipmentItemCardViewModel(item: item.packageItem, currency: order.currency)
                )
            }
        }

        // Step 2: Update the current shipment
        shipments[currentIndex] = newShipment

        // Step 3: Add new or update existing shipment
        let totalItemsMoved = movedItems
            .map { $0.packageItem.quantity }
            .reduce(0, +)
        var updatedShipmentIndex: Int?

        switch destination {
        case .newShipment:
            shipments.append(movedItems)
            updatedShipmentIndex = shipments.count - 1

        case .existingShipment(let index):
            var updatedShipment = Shipment()
            for item in shipments[index] {
                let matchingItemIndex = movedItems.firstIndex(where: {
                    $0.packageItem.productOrVariationID == item.packageItem.productOrVariationID
                })
                if let matchingItemIndex {
                    // Merge the quantity if the same item is moved to the shipment
                    let updatedQuantity = item.packageItem.quantity + movedItems[matchingItemIndex].packageItem.quantity
                    let updatedItem = ShippingLabelPackageItem(copy: item.packageItem, quantity: updatedQuantity)
                    updatedShipment.append(
                        CollapsibleShipmentItemCardViewModel(item: updatedItem, currency: order.currency)
                    )
                    movedItems.remove(at: matchingItemIndex)
                } else {
                    // Keep the item as-is
                    updatedShipment.append(item)
                }
            }
            // Add the rest of the new items to the shipment
            updatedShipment.append(contentsOf: movedItems)
            shipments[index] = updatedShipment
            updatedShipmentIndex = index
        }

        // Step 4: Remove the current shipment if it's empty.
        // Then update the section header and selection callback
        if currentShipment.isEmpty {
            shipments.remove(at: currentIndex)
            if shipments.count <= currentIndex {
                selectedShipmentIndex = max(shipments.count - 1, 0)
            }
        }
        configureSelectionCallback()
        configureSectionHeader()

        // Step 5: Trigger notice for moving completion.
        let itemsCount = Localization.itemsCount(totalItemsMoved)
        let displayedShipmentIndex = (updatedShipmentIndex ?? 0) + 1
        let shipmentLabel = String.localizedStringWithFormat(Localization.shipmentFormat, displayedShipmentIndex)
        withAnimation {
            movingCompletionMessage = {
                let content = String.localizedStringWithFormat(Localization.movingCompletionFormat, itemsCount, shipmentLabel)

                var attributedText = AttributedString(content)
                attributedText.font = .headline
                attributedText.foregroundColor = Color(.textInverted)

                return attributedText
            }()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + Constants.movingCompletionNoticeDuration) {
            withAnimation {
                self.movingCompletionMessage = nil
            }
            self.undoMovingItemsHandler = nil
        }
    }

    func undoMovingItems() {
        undoMovingItemsHandler?()
        movingCompletionMessage = nil
    }

    func mergeAllUnfulfilledShipments() {
        var mergedShipment = Shipment()

        // TODO-15440: check for fulfilled shipments and remove them from the list.
        shipments.forEach { shipment in
            for item in shipment {
                let matchingItemIndex = mergedShipment.firstIndex(where: {
                    $0.packageItem.productOrVariationID == item.packageItem.productOrVariationID
                })
                if let matchingItemIndex {
                    // Merge the quantity if the same item is merged to the shipment
                    let updatedQuantity = item.packageItem.quantity + mergedShipment[matchingItemIndex].packageItem.quantity
                    let updatedItem = ShippingLabelPackageItem(copy: item.packageItem, quantity: updatedQuantity)
                    mergedShipment[matchingItemIndex] = CollapsibleShipmentItemCardViewModel(item: updatedItem, currency: order.currency)
                } else {
                    // Keep the item as-is
                    mergedShipment.append(item)
                }
            }
        }

        shipments = [mergedShipment]
        selectedShipmentIndex = 0
    }

    func configureDescription(for shipment: Shipment, index: Int) -> ShipmentDescription {
        let items = shipment.map(\.packageItem)
        let itemsCount = items.map(\.quantity).reduce(0, +)
        let quantity = Localization.itemsCount(itemsCount)
        let weight = formatWeight(for: items)
        let price = formatPrice(for: items)
        let title = String.localizedStringWithFormat(Localization.shipmentFormat, index + 1)
        return ShipmentDescription(title: title, quantity: quantity, weight: weight, price: price)
    }
}

private extension WooShippingSplitShipmentsViewModel {
    func configureSelectionCallback() {
        currentShipment.forEach { viewModel in
            viewModel.onSelectionChange = { [weak self] in
                self?.updateMoveToNotice()
            }
        }
    }

    func showInstructionsNotice() {
        guard dismissedInstructions == false else {
            return
        }
        instructions = {
            let moveToNewShipmentTitle = MoveToShipmentNotice.Localization.moveToNewShipment
            let content = String.localizedStringWithFormat(Localization.SelectionInstructionsNotice.message, moveToNewShipmentTitle)

            var attributedText = AttributedString(content)
            attributedText.font = .body
            attributedText.foregroundColor = Color(.textInverted)

            if let range = attributedText.range(of: moveToNewShipmentTitle) {
                let textStyleContainer = AttributeContainer()
                    .font(.body.weight(.semibold))
                    .foregroundColor(Color(.textInverted))
                attributedText[range].setAttributes(textStyleContainer)
            }

            return attributedText
        }()
    }

    func updateMoveToNotice() {
        let currentIndex = selectedShipmentIndex
        let selectedItemsCount = currentShipment
            .map(\.numberOfSelectedItems)
            .reduce(0, +)

        guard selectedItemsCount > 0 else {
            return moveToNoticeViewModel = nil
        }

        let totalItemCount = currentShipment
            .map { $0.packageItem.quantity }
            .reduce(0, +).intValue

        if shipments.count == 1 &&
            selectedItemsCount == totalItemCount {
            // do not allow moving all items if there is only one shipment at the moment
            return moveToNoticeViewModel = nil
        }

        moveToNoticeViewModel = MoveToShipmentNoticeViewModel(selectedItemsCount: selectedItemsCount,
                                                              existingShipmentsCount: shipments.count,
                                                              currentShipmentIndex: currentIndex)
    }

    /// Configures the labels in the section header.
    ///
    func configureSectionHeader() {
        let description = configureDescription(for: currentShipment, index: selectedShipmentIndex)
        itemsCountLabel = description.quantity
        itemsWeightLabel = description.weight
        itemsPriceLabel = description.price
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

extension WooShippingSplitShipmentsViewModel {
    struct ShipmentDescription {
        let title: String
        let quantity: String
        let weight: String
        let price: String
    }
}

// MARK: Constants
private extension WooShippingSplitShipmentsViewModel {
    enum Constants {
        static let movingCompletionNoticeDuration: Double = 3 // seconds
    }

    enum Localization {
        enum SelectionInstructionsNotice {
            static let message = NSLocalizedString(
                "wooShipping.createLabels.splitShipment.SelectionInstructionsNotice.message",
                value: "To split, select the items, and tap %1$@ when the toolbar appears.",
                comment: "Instructions to ask customer to select items to split during shipping label creation. " +
                "The placeholder is title of a button to move items to a new shipment ."
            )

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

        static let movingCompletionFormat = NSLocalizedString(
            "wooShipping.createLabels.splitShipment.movingCompletionFormat",
            value: "Moved %1$@ to %2$@",
            comment: "Message to be displayed after moving items between shipments in the shipping label creation flow. " +
            "The placeholders are the number of items and shipment index respectively. " +
            "Reads as: 'Moved 3 items to Shipment 2'."
        )
    }
}
