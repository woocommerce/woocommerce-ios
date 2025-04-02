import SwiftUI
import Yosemite
import WooFoundation

/// ViewModel for `WooShippingSplitShipmentsDetailView`
final class WooShippingSplitShipmentsViewModel: ObservableObject {
    private let order: Order
    private let stores: StoresManager
    private let currencySettings: CurrencySettings
    private let shippingSettingsService: ShippingSettingsService

    typealias ShipmentContents = [CollapsibleShipmentItemCardViewModel]

    @Published private(set) var shipments: [Shipment]

    @Published var selectedShipmentIndex = 0 {
        didSet {
            configureSectionHeader()
            configureSelectionCallback()
            updateMoveToNotice()
        }
    }

    /// Shipment info saved in remote. Used to compare with locally edited info and enable "Done" button
    ///
    @Published private var shipmentsSavedInRemote: WooShippingUpdateShipment?

    /// Edited shipments info to send to remote
    ///
    private var editedShipmentsInfo: WooShippingUpdateShipment {
        var shipmentsForRemote = [String: [WooShippingShipmentItem]]()
        var shipmentIdsToUpdate = [String]()
        for (index, shipment) in shipments.enumerated() {
            let key = "\(index)"
            // TODO: 15309 Investigate which IDs need to be sent to remote
            shipmentIdsToUpdate.append(key)

            var items = [WooShippingShipmentItem]()
            for item in shipment.contents {
                if let mainItemID = Int(item.mainItemRow.itemID) {
                    let i = WooShippingShipmentItem(id: Int64(mainItemID),
                                                    subItems: item.childItemRows.map({ $0.itemID }))
                    items.append(i)
                } else {
                    DDLogError("Unable to parse main item ID from \(item.mainItemRow.itemID)")
                }
            }

            shipmentsForRemote[key] = items
        }

        let shipment = WooShippingUpdateShipment(shipmentIdsToUpdate: shipmentIdsToUpdate,
                                                 shipments: shipmentsForRemote)
        return shipment
    }

    /// Enables "Done" button only if shipments are edited
    ///
    var enableDoneButton: Bool {
        shipmentsSavedInRemote != editedShipmentsInfo
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

    private let purchasedIcon = UIImage(systemName: "checkmark.circle.fill")?.withRenderingMode(.alwaysTemplate)

    var topTabItems: [TopTabItem<EmptyView>] {
        shipments.enumerated().map { (index, item) in
            return TopTabItem(name: String.localizedStringWithFormat(Localization.shipmentFormat, index + 1),
                              icon: item.isPurchased ? purchasedIcon : nil,
                              content: { EmptyView() })
        }
    }

    var currentShipment: Shipment {
        shipments[selectedShipmentIndex]
    }

    @Published private(set) var moveToNoticeViewModel: MoveToShipmentNoticeViewModel?

    @Published private(set) var instructions: AttributedString?
    private var dismissedInstructions: Bool = false

    @Published private(set) var movingCompletionMessage: AttributedString?
    private var undoMovingItemsHandler: (() -> Void)?

    @Published private(set) var isSavingShipmentInfo = false

    init(order: Order,
         shipments: [Shipment],
         stores: StoresManager = ServiceLocator.stores,
         currencySettings: CurrencySettings = ServiceLocator.currencySettings,
         shippingSettingsService: ShippingSettingsService = ServiceLocator.shippingSettingsService) {
        self.order = order
        self.stores = stores
        self.currencySettings = currencySettings
        self.shippingSettingsService = shippingSettingsService
        self.shipments = shipments

        shipmentsSavedInRemote = editedShipmentsInfo

        configureSectionHeader()
        configureSelectionCallback()
    }

    func onAppear() {
        showInstructionsNotice()
        updateMoveToNotice()
    }

    func selectAll() {
        currentShipment.contents.forEach {
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
        var newShipmentContents = ShipmentContents()
        var movedItems = ShipmentContents()
        for item in currentShipment.contents {
            let initialQuantity = item.packageItem.quantity.intValue
            let selectedQuantity = item.numberOfSelectedItems
            let remainingQuantity = initialQuantity - selectedQuantity
            if remainingQuantity == 0 {
                movedItems.append(
                    CollapsibleShipmentItemCardViewModel(item: item.packageItem, currency: order.currency)
                )
            } else if selectedQuantity > 0 {
                let newItem = ShippingLabelPackageItem(copy: item.packageItem, quantity: Decimal(remainingQuantity))
                newShipmentContents.append(
                    CollapsibleShipmentItemCardViewModel(item: newItem, currency: order.currency)
                )
                let movedItem = ShippingLabelPackageItem(copy: item.packageItem, quantity: Decimal(selectedQuantity))
                movedItems.append(
                    CollapsibleShipmentItemCardViewModel(item: movedItem, currency: order.currency)
                )
            } else if selectedQuantity == 0 {
                newShipmentContents.append(
                    CollapsibleShipmentItemCardViewModel(item: item.packageItem, currency: order.currency)
                )
            }
        }

        // Step 2: Update the current shipment
        shipments[currentIndex] = createShipment(with: newShipmentContents)

        // Step 3: Add new or update existing shipment
        let totalItemsMoved = movedItems
            .map { $0.packageItem.quantity }
            .reduce(0, +)
        var updatedShipmentIndex: Int?

        switch destination {
        case .newShipment:
            let newShipment = createShipment(with: movedItems)
            shipments.append(newShipment)
            updatedShipmentIndex = shipments.count - 1

        case .existingShipment(let index):
            var updatedShipmentContents = ShipmentContents()
            for item in shipments[index].contents {
                let matchingItemIndex = movedItems.firstIndex(where: {
                    $0.packageItem.productOrVariationID == item.packageItem.productOrVariationID
                })
                if let matchingItemIndex {
                    // Merge the quantity if the same item is moved to the shipment
                    let updatedQuantity = item.packageItem.quantity + movedItems[matchingItemIndex].packageItem.quantity
                    let updatedItem = ShippingLabelPackageItem(copy: item.packageItem, quantity: updatedQuantity)
                    updatedShipmentContents.append(
                        CollapsibleShipmentItemCardViewModel(item: updatedItem, currency: order.currency)
                    )
                    movedItems.remove(at: matchingItemIndex)
                } else {
                    // Keep the item as-is
                    updatedShipmentContents.append(item)
                }
            }
            // Add the rest of the new items to the shipment
            updatedShipmentContents.append(contentsOf: movedItems)
            shipments[index] = createShipment(with: updatedShipmentContents)
            updatedShipmentIndex = index
        }

        // Step 4: Remove the current shipment if it's empty.
        // Then update the section header and selection callback
        if currentShipment.contents.isEmpty {
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

    @MainActor
    func saveShipmentInfo() async throws {
        isSavingShipmentInfo = true
        try await updateShipment()
        isSavingShipmentInfo = false
    }

    func mergeAllUnfulfilledShipments() {
        let (unfulfilledShipments, fulfilledShipments) = shipments.partitioned(by: { $0.isPurchased })
        var mergedShipmentContents = ShipmentContents()

        unfulfilledShipments.forEach { shipment in
            for item in shipment.contents {
                let matchingItemIndex = mergedShipmentContents.firstIndex(where: {
                    $0.packageItem.productOrVariationID == item.packageItem.productOrVariationID
                })
                if let matchingItemIndex {
                    // Merge the quantity if the same item is merged to the shipment
                    let updatedQuantity = item.packageItem.quantity + mergedShipmentContents[matchingItemIndex].packageItem.quantity
                    let updatedItem = ShippingLabelPackageItem(copy: item.packageItem, quantity: updatedQuantity)
                    mergedShipmentContents[matchingItemIndex] = CollapsibleShipmentItemCardViewModel(item: updatedItem, currency: order.currency)
                } else {
                    // Keep the item as-is
                    mergedShipmentContents.append(item)
                }
            }
        }

        shipments = [createShipment(with: mergedShipmentContents)] + fulfilledShipments
        selectedShipmentIndex = 0
    }

    func retrieveName(for shipment: Shipment) -> String {
        guard let index = shipments.firstIndex(where: { $0.id == shipment.id }) else {
            DDLogWarn("⚠️ Cannot retrieve name for shipment \(shipment)")
            return ""
        }

        return String.localizedStringWithFormat(Localization.shipmentFormat, index + 1)
    }

    func shipmentsToMerge(for shipment: Shipment) -> [Shipment] {
        shipments.filter { $0 != shipment }
    }

    func removeShipment(_ shipment: Shipment, mergeInto otherShipment: Shipment) {
        guard let removedShipmentIndex = shipments.firstIndex(where: { $0 == shipment }),
              let mergedShipmentIndex = shipments.firstIndex(where: { $0 == otherShipment }) else {
            DDLogWarn("⚠️ Cannot find shipments to remove or merge!")
            return
        }

        var mergedContents = otherShipment.contents

        for item in shipment.contents {
            let matchingItemIndex = mergedContents.firstIndex(where: {
                $0.packageItem.productOrVariationID == item.packageItem.productOrVariationID
            })
            if let matchingItemIndex {
                // Merge the quantity if the same item is merged to the shipment
                let updatedQuantity = item.packageItem.quantity + mergedContents[matchingItemIndex].packageItem.quantity
                let updatedItem = ShippingLabelPackageItem(copy: item.packageItem, quantity: updatedQuantity)
                mergedContents[matchingItemIndex] = CollapsibleShipmentItemCardViewModel(item: updatedItem, currency: order.currency)
            } else {
                // Append the item as-is
                mergedContents.append(item)
            }
        }

        let mergedShipment = createShipment(with: mergedContents)
        shipments[mergedShipmentIndex] = mergedShipment
        shipments.remove(at: removedShipmentIndex)
        selectedShipmentIndex = shipments.firstIndex(where: { $0 == mergedShipment }) ?? 0
    }
}

private extension WooShippingSplitShipmentsViewModel {
    func configureSelectionCallback() {
        currentShipment.contents.forEach { viewModel in
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
        let selectedItemsCount = currentShipment.contents
            .map(\.numberOfSelectedItems)
            .reduce(0, +)

        guard selectedItemsCount > 0 else {
            return moveToNoticeViewModel = nil
        }

        let totalItemCount = currentShipment.contents
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
        itemsCountLabel = currentShipment.quantity
        itemsWeightLabel = currentShipment.weight
        itemsPriceLabel = currentShipment.price
    }
}

// MARK: Shipments

extension WooShippingSplitShipmentsViewModel {

    private func createShipment(with contents: [CollapsibleShipmentItemCardViewModel]) -> Shipment {
        Shipment(contents: contents,
                 currency: order.currency,
                 currencySettings: currencySettings,
                 shippingSettingsService: shippingSettingsService)
    }

    struct Shipment: Identifiable, Equatable {

        let id = UUID().uuidString
        let contents: [CollapsibleShipmentItemCardViewModel]
        let isPurchased: Bool

        let quantity: String
        let weight: String
        let price: String

        /// Label with the details of the items to ship.
        /// Includes total weight and total price for all items in the current shipment.
        var itemsDetailLabel: String {
            "\(weight) • \(price)"
        }

        init(contents: [CollapsibleShipmentItemCardViewModel],
             isPurchased: Bool = false,
             currency: String,
             currencySettings: CurrencySettings,
             shippingSettingsService: ShippingSettingsService) {
            self.contents = contents
            self.isPurchased = isPurchased

            let items = contents.map(\.packageItem)
            let itemsCount = items.map(\.quantity).reduce(0, +)
            self.quantity = Localization.itemsCount(itemsCount)
            self.weight = formatWeight(for: items)
            self.price = formatPrice(for: items)

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
                return currencyFormatter.formatAmount(totalPrice, with: currency) ?? totalPrice.description
            }
        }

        static func == (lhs: WooShippingSplitShipmentsViewModel.Shipment, rhs: WooShippingSplitShipmentsViewModel.Shipment) -> Bool {
            lhs.id == rhs.id
        }
    }

    @discardableResult
    @MainActor
    private func updateShipment() async throws -> WooShippingShipments {
        let shipments = editedShipmentsInfo
        return try await withCheckedThrowingContinuation { continuation in
            let action = WooShippingAction.updateShipment(siteID: order.siteID,
                                                          orderID: order.orderID,
                                                          shipmentToUpdate: shipments) { [weak self] result in
                guard let self else { return }

                switch result {
                case .success(let shipmentResponse):
                    shipmentsSavedInRemote = shipments
                    continuation.resume(returning: shipmentResponse)
                case .failure(let error):
                    DDLogError("⛔️ Error updating shipments for Woo Shipping labels: \(error)")
                    continuation.resume(throwing: error)
                }
            }
            stores.dispatch(action)
        }
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
