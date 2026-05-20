import SwiftUI
import Yosemite
import WooFoundation

typealias Shipment = WooShippingSplitShipmentsViewModel.Shipment

/// ViewModel for `WooShippingSplitShipmentsDetailView`
final class WooShippingSplitShipmentsViewModel: ObservableObject {
    private let order: Order
    private let stores: StoresManager
    private let currencySettings: CurrencySettings
    private let shippingSettingsService: ShippingSettingsService

    typealias ShipmentContents = [CollapsibleShipmentItemCardViewModel]

    @Published private(set) var shipments: [Shipment]

    /// Returns shipments that can be removed and merged into other shipments.
    /// A shipment can be removed if:
    /// 1. It is not purchased
    /// 2. It is not the last unfulfilled shipment
    @Published private(set) var removableShipments: [Shipment] = []

    @Published var selectedShipmentIndex = 0 {
        didSet {
            configureSectionHeader()
            configureSelectionCallback()
            updateMoveToNotice()
        }
    }

    /// Shipment info saved in remote. Used to compare with locally edited info and enable "Done" button
    ///
    @Published private var shipmentsSavedInRemote: [Shipment]

    /// Edited shipments info to send to remote
    ///
    private var editedShipmentsInfo: WooShippingShipments {
        var shipmentsForRemote = [String: [WooShippingShipmentItem]]()
        for shipment in shipments.sorted(by: { $0.index < $1.index}) {
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

            shipmentsForRemote[shipment.index.description] = items
        }

        return shipmentsForRemote
    }

    var containsUnsavedChanges: Bool {
        shipmentsSavedInRemote != shipments
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

    var isSelectAllItemsDisabled: Bool {
        return currentShipment.isPurchased || isSavingShipmentInfo
    }

    @Published private(set) var moveToNoticeViewModel: MoveToShipmentNoticeViewModel?

    @Published private(set) var instructions: AttributedString?
    private var dismissedInstructions: Bool = false

    @Published private(set) var movingCompletionMessage: AttributedString?
    private var undoMovingItemsHandler: (() -> Void)?

    @Published private(set) var isSavingShipmentInfo = false

    /// Whether to show the error alert for saving shipment info
    @Published var shouldShowSaveShipmentErrorAlert = false

    /// Whether the remove shipment menu should be displayed.
    /// The menu is shown when there are removable shipments or when merge all unfulfilled is available.
    var shouldShowRemoveShipmentMenu: Bool {
        removableShipments.isNotEmpty || isMergeAllUnfulfilledAvailable()
    }

    init(order: Order,
         remoteShipments: [WooShippingShipment],
         items: [ShippingLabelPackageItem],
         stores: StoresManager = ServiceLocator.stores,
         currencySettings: CurrencySettings = ServiceLocator.currencySettings,
         shippingSettingsService: ShippingSettingsService = ServiceLocator.shippingSettingsService) {
        self.order = order
        self.stores = stores
        self.currencySettings = currencySettings
        self.shippingSettingsService = shippingSettingsService

        let shipments = Self.createShipments(with: remoteShipments,
                                             packageItems: items,
                                             currency: order.currency,
                                             currencySettings: currencySettings,
                                             shippingSettingsService: shippingSettingsService)

        self.shipments = shipments
        shipmentsSavedInRemote = shipments

        configureSectionHeader()
        configureSelectionCallback()
        configureRemovableShipments()
    }

    func onAppear() {
        if shipments.count == 1 {
            showInstructionsNotice()
        }
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

    func revertChanges() {
        shipments = shipmentsSavedInRemote
        selectedShipmentIndex = 0
    }

    func didPurchaseLabel(for shipmentIndex: Int, label: ShippingLabel) {
        let currentShipment = shipments[shipmentIndex]
        let updatedContents = currentShipment.contents.map {
            CollapsibleShipmentItemCardViewModel(item: $0.packageItem, isSelectable: false, currency: order.currency)
        }
        shipments[shipmentIndex] = Shipment(index: shipmentIndex,
                                            contents: updatedContents,
                                            purchasedLabel: label,
                                            currency: order.currency,
                                            currencySettings: currencySettings,
                                            shippingSettingsService: shippingSettingsService)
        shipmentsSavedInRemote = shipments
    }

    func didRequestRefund(for shipmentIndex: Int) {
        let currentShipment = shipments[shipmentIndex]
        let updatedContents = currentShipment.contents.map {
            CollapsibleShipmentItemCardViewModel(item: $0.packageItem, isSelectable: true, currency: order.currency)
        }
        shipments[shipmentIndex] = Shipment(index: shipmentIndex,
                                            contents: updatedContents,
                                            purchasedLabel: nil,
                                            currency: order.currency,
                                            currencySettings: currencySettings,
                                            shippingSettingsService: shippingSettingsService)
        shipmentsSavedInRemote = shipments
    }

    func moveSelectedItems(to destination: MoveToShipmentNoticeViewModel.Destination) {
        defer {
            updateShipmentIndices() // !!IMPORTANT!!
        }
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
        defer {
            isSavingShipmentInfo = false
        }

        do {
            try await updateShipment()
        } catch {
            shouldShowSaveShipmentErrorAlert = true
            throw error
        }
    }

    func mergeAllUnfulfilledShipments() {
        defer {
            updateShipmentIndices() // !!IMPORTANT!!
        }
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
        String.localizedStringWithFormat(Localization.shipmentFormat, shipment.index + 1)
    }

    /// Determines if a shipment's delete option should be available.
    /// A shipment's delete option should be available if:
    /// 1. The shipment is not purchased
    /// 2. The view model is not currently saving shipment info
    /// 3. The shipment is not the last unfulfilled shipment
    func isShipmentDeleteOptionAvailable(for shipment: Shipment) -> Bool {
        if shipment.isPurchased || isSavingShipmentInfo {
            return false
        }

        let unfulfilledShipments = shipments.filter { !$0.isPurchased }
        return unfulfilledShipments.count > 1 || unfulfilledShipments.first != shipment
    }

    /// Determines if the "merge all unfulfilled" option should be available.
    /// The option should be available if:
    /// 1. The view model is not currently saving shipment info
    /// 2. There are more than two unfulfilled shipments
    func isMergeAllUnfulfilledAvailable() -> Bool {
        if isSavingShipmentInfo {
            return false
        }

        let unfulfilledShipments = shipments.filter { !$0.isPurchased }
        return unfulfilledShipments.count > 2
    }

    /// Returns shipments that can be merged into.
    /// A shipment can be merged into if:
    /// 1. It is not purchased
    /// 2. It is not the last unfulfilled shipment
    func shipmentsToMerge(for shipment: Shipment) -> [Shipment] {
        shipments.filter { otherShipment in
            otherShipment != shipment && isShipmentDeleteOptionAvailable(for: otherShipment)
        }
    }

    func removeShipment(_ shipment: Shipment, mergeInto otherShipment: Shipment) {
        defer {
            updateShipmentIndices() // !!IMPORTANT!!
        }

        let removedShipmentIndex = shipment.index
        let mergedShipmentIndex = otherShipment.index
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

    /// Returns shipments that can be removed and merged into other shipments.
    /// A shipment can be removed if:
    /// 1. It is not purchased
    /// 2. It is not the last unfulfilled shipment
    func configureRemovableShipments() {
        $shipments
            .map { shipments in
                shipments.filter { [weak self] shipment in
                    self?.isShipmentDeleteOptionAvailable(for: shipment) ?? false
                }
            }
            .assign(to: &$removableShipments)
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
            moveToNoticeViewModel = nil
            return
        }

        let totalItemCount = currentShipment.contents
            .map { $0.packageItem.quantity }
            .reduce(0, +).intValue

        let allItemsSelected = selectedItemsCount == totalItemCount
        let existingShipmentsIndexesToMove = shipments.enumerated()
            .filter { $0.element.isPurchased == false && $0.offset != currentIndex }
            .map { $0.offset }

        if shipments.count == 1 && allItemsSelected {
            // do not allow moving all items if there is only one shipment at the moment
            moveToNoticeViewModel = nil
            return
        } else if existingShipmentsIndexesToMove.isEmpty && allItemsSelected {
            // prevent moving all items if all other shipments are fulfilled
            moveToNoticeViewModel = nil
            return
        }

        moveToNoticeViewModel = MoveToShipmentNoticeViewModel(
            allItemsSelected: allItemsSelected,
            selectedItemsCount: selectedItemsCount,
            existingShipmentsIndexesToMove: existingShipmentsIndexesToMove
        )
    }

    /// Configures the labels in the section header.
    ///
    func configureSectionHeader() {
        itemsCountLabel = currentShipment.quantity
        itemsWeightLabel = currentShipment.weight
        itemsPriceLabel = currentShipment.price
    }

    /// Ensure that indices in the shipments are correct based on the list order.
    ///
    func updateShipmentIndices() {
        var newShipmentList: [Shipment] = []
        for (index, shipment) in shipments.enumerated() {
            let copy = shipment.copy(newIndex: index)
            newShipmentList.append(copy)
        }
        shipments = newShipmentList
    }
}

// MARK: Shipments

extension WooShippingSplitShipmentsViewModel {

    private static func createShipments(with remoteShipments: [WooShippingShipment],
                                        packageItems: [ShippingLabelPackageItem],
                                        currency: String,
                                        currencySettings: CurrencySettings,
                                        shippingSettingsService: ShippingSettingsService) -> [Shipment] {
        guard remoteShipments.isEmpty == false else {
            let contents = packageItems.map { item in
                CollapsibleShipmentItemCardViewModel(item: item, currency: currency)
            }
            let shipment = Shipment(contents: contents,
                                    currency: currency,
                                    currencySettings: currencySettings,
                                    shippingSettingsService: shippingSettingsService)
            return [shipment]
        }

        let shipments = remoteShipments
            .sorted(by: { $0.index.localizedStandardCompare($1.index) == .orderedAscending })
            .map { shipment in
                var shipmentContents = ShipmentContents()
                for shipmentItem in shipment.items {
                    guard let packageItem = packageItems.first(where: { $0.orderItemID == shipmentItem.id }) else {
                        continue
                    }

                    let updatedItem = ShippingLabelPackageItem(copy: packageItem,
                                                               quantity: shipmentItem.quantity)
                    let content = CollapsibleShipmentItemCardViewModel(item: updatedItem,
                                                                       isSelectable: shipment.shippingLabel == nil,
                                                                       currency: currency)
                    shipmentContents.append(content)
                }

                let purchasedLabel: ShippingLabel? = {
                    guard let label = shipment.shippingLabel, label.refund == nil else {
                        return nil
                    }
                    return label
                }()
                return Shipment(index: Int(shipment.index) ?? 0,
                                contents: shipmentContents,
                                purchasedLabel: purchasedLabel,
                                currency: currency,
                                currencySettings: currencySettings,
                                shippingSettingsService: shippingSettingsService)
            }
        return shipments
    }

    private func createShipment(with contents: [CollapsibleShipmentItemCardViewModel]) -> Shipment {
        Shipment(contents: contents,
                 currency: order.currency,
                 currencySettings: currencySettings,
                 shippingSettingsService: shippingSettingsService)
    }

    struct Shipment: Identifiable, Equatable {

        /// Underlying ID - do not use this to send to API requests.
        let id: String

        /// Index of the shipment in the shipment list - used to identify shipments in API requests.
        let index: Int

        let contents: [CollapsibleShipmentItemCardViewModel]
        let purchasedLabel: ShippingLabel?

        let quantity: String
        let weight: String
        let price: String

        /// Label with the details of the items to ship.
        /// Includes total weight and total price for all items in the current shipment.
        var itemsDetailLabel: String {
            "\(weight) • \(price)"
        }

        var items: [ShippingLabelPackageItem] {
            contents.map(\.packageItem)
        }

        var isPurchased: Bool {
            purchasedLabel != nil
        }

        private let currency: String
        private let currencySettings: CurrencySettings
        private let shippingSettingsService: ShippingSettingsService

        init(id: String = UUID().uuidString,
             index: Int = 0,
             contents: [CollapsibleShipmentItemCardViewModel],
             purchasedLabel: ShippingLabel? = nil,
             currency: String,
             currencySettings: CurrencySettings,
             shippingSettingsService: ShippingSettingsService) {
            self.id = id
            self.index = index
            self.contents = contents
            self.purchasedLabel = purchasedLabel

            let items = contents.map(\.packageItem)
            let itemsCount = items.map(\.quantity).reduce(0, +)
            self.quantity = Localization.itemsCount(itemsCount)
            self.weight = formatWeight(for: items)
            self.price = formatPrice(for: items)

            self.currency = currency
            self.currencySettings = currencySettings
            self.shippingSettingsService = shippingSettingsService

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

        func copy(newIndex: Int) -> Shipment {
            Shipment(id: id,
                     index: newIndex,
                     contents: contents,
                     purchasedLabel: purchasedLabel,
                     currency: currency,
                     currencySettings: currencySettings,
                     shippingSettingsService: shippingSettingsService)
        }
    }

    @discardableResult
    @MainActor
    private func updateShipment() async throws -> WooShippingShipments {
        let shipmentIdsToUpdate: [String: Int] = {
            var indicesMap: [String: Int] = [:]
            for item in shipmentsSavedInRemote.filter({ $0.isPurchased }) {
                guard let matchingItem = shipments.first(where: { $0 == item }) else {
                    DDLogWarn("⚠️ Cannot find matching fulfilled shipment to update at index: \(item.index)")
                    continue
                }
                if item.index != matchingItem.index {
                    indicesMap[item.index.description] = matchingItem.index
                }
            }
            return indicesMap
        }()
        let shipmentsInfo = WooShippingUpdateShipment(shipmentIdsToUpdate: shipmentIdsToUpdate,
                                                      shipments: editedShipmentsInfo)
        return try await withCheckedThrowingContinuation { continuation in
            let action = WooShippingAction.updateShipment(siteID: order.siteID,
                                                          orderID: order.orderID,
                                                          shipmentToUpdate: shipmentsInfo) { [weak self] result in
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
