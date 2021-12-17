import Foundation
import Yosemite

/// ViewModel for presenting the issue refund screen to the user.
///
final class IssueRefundViewModel {

    /// Struct to hold the necessary state to perform the refund and update the view model
    ///
    private struct State {
        /// Order to be refunded
        ///
        let order: Order

        /// Refunds previously made
        ///
        let refunds: [Refund]

        /// Items to refund. Order Items - Refunded items
        ///
        let itemsToRefund: [RefundableOrderItem]

        /// Current currency settings
        ///
        let currencySettings: CurrencySettings

        /// Bool indicating if shipping will be refunded
        ///
        var shouldRefundShipping: Bool = false

        /// Bool indicating if fees will be refunded
        ///
        var shouldRefundFees: Bool = false

        ///  Holds the quantity of items to refund
        ///
        var refundQuantityStore = RefundQuantityStore()
    }

    /// Current ViewModel state
    ///
    private var state: State {
        didSet {
            sections = createSections()
            title = calculateTitle()
            selectedItemsTitle = createSelectedItemsCount()
            isNextButtonEnabled = calculateNextButtonEnableState()
            hasUnsavedChanges = calculatePendingChangesState()
            onChange?()
        }
    }

    /// Closure to notify the `ViewController` when the view model properties change
    ///
    var onChange: (() -> (Void))?

    /// Title for the navigation bar
    ///
    private(set) var title: String = ""

    /// String indicating how many items the user has selected to refund
    ///
    private(set) var selectedItemsTitle: String = ""

    /// Boolean indicating if the next button is enabled
    ///
    private(set) var isNextButtonEnabled: Bool = false

    /// Boolean indicating if the "select all" button is visible
    ///
    private(set) var isSelectAllButtonVisible: Bool = true

    /// Boolean indicating if there are refunds pending to commit
    ///
    private(set) var hasUnsavedChanges: Bool = false

    /// The sections and rows to display in the `UITableView`.
    ///
    private(set) var sections: [Section] = []

    /// Products related to this order. Needed to build `RefundItemViewModel` rows
    ///
    private lazy var products: [Product] = {
        let resultsController = createProductsResultsController()
        try? resultsController.performFetch()
        return resultsController.fetchedObjects
    }()

    /// Payment Gateway related to the order. Needed to build `Refund Via` section.
    ///
    private lazy var paymentGateway: PaymentGateway? = {
        let resultsController = createPaymentGatewayResultsController()
        try? resultsController.performFetch()
        return resultsController.fetchedObjects.first
    }()

    private let analytics: Analytics

    init(order: Order, refunds: [Refund], currencySettings: CurrencySettings, analytics: Analytics = ServiceLocator.analytics) {
        self.analytics = analytics
        let items = Self.filterItems(from: order, with: refunds)
        state = State(order: order, refunds: refunds, itemsToRefund: items, currencySettings: currencySettings)
        sections = createSections()
        title = calculateTitle()
        isNextButtonEnabled = calculateNextButtonEnableState()
        isSelectAllButtonVisible = calculateSelectAllButtonVisibility()
        selectedItemsTitle = createSelectedItemsCount()
        hasUnsavedChanges = calculatePendingChangesState()
    }

    /// Creates the `ViewModel` to be used when navigating to the page where the user can
    /// confirm and submit the refund.
    func createRefundConfirmationViewModel() -> RefundConfirmationViewModel {
        let details = RefundConfirmationViewModel.Details(order: state.order,
                                                          amount: "\(calculateRefundTotal())",
                                                          refundsShipping: state.shouldRefundShipping,
                                                          refundsFees: state.shouldRefundFees,
                                                          items: state.refundQuantityStore.refundableItems(),
                                                          paymentGateway: paymentGateway)
        return RefundConfirmationViewModel(details: details, currencySettings: state.currencySettings)
    }
}

// MARK: User Actions
extension IssueRefundViewModel {
    /// Toggles the refund shipping state
    ///
    func toggleRefundShipping() {
        state.shouldRefundShipping.toggle()
        trackShippingSwitchChanged()
    }

    func toggleRefundFees() {
        state.shouldRefundFees.toggle()
    }

    /// Returns the number of items available for refund for the provided item index.
    /// Returns `nil` if the index is out of bounds
    ///
    func quantityAvailableForRefundForItemAtIndex(_ itemIndex: Int) -> Int? {
        guard let refundable = state.itemsToRefund[safe: itemIndex] else {
            return nil
        }
        return refundable.quantity
    }

    /// Returns the current quantity set for refund for the provided item index.
    /// Returns `nil` if the index is out of bounds.
    ///
    func currentQuantityForItemAtIndex(_ itemIndex: Int) -> Int? {
        guard let refundable = state.itemsToRefund[safe: itemIndex] else {
            return nil
        }
        return state.refundQuantityStore.refundQuantity(for: refundable.item)
    }

    /// Updates the quantity to be refunded for an item on the provided index.
    ///
    func updateRefundQuantity(quantity: Int, forItemAtIndex itemIndex: Int) {
        guard let refundable = state.itemsToRefund[safe: itemIndex] else {
            return
        }
        state.refundQuantityStore.update(quantity: quantity, for: refundable.item)
    }

    /// Marks all items as to be refunded
    ///
    func selectAllOrderItems() {
        state.itemsToRefund.forEach { refundable in
            state.refundQuantityStore.update(quantity: refundable.quantity, for: refundable.item)
        }

        trackSelectAllButtonTapped()
    }
}

// MARK: Analytics
extension IssueRefundViewModel {
    /// Tracks when the shipping switch state changes
    ///
    private func trackShippingSwitchChanged() {
        let action: WooAnalyticsEvent.IssueRefund.ShippingSwitchState = state.shouldRefundShipping ? .on : .off
        analytics.track(event: WooAnalyticsEvent.IssueRefund.shippingSwitchTapped(orderID: state.order.orderID, state: action))
    }

    /// Tracks when the user taps the "next" button
    ///
    func trackNextButtonTapped() {
        analytics.track(event: WooAnalyticsEvent.IssueRefund.nextButtonTapped(orderID: state.order.orderID))
    }

    /// Tracks when the user taps the "quantity" button
    ///
    func trackQuantityButtonTapped() {
        analytics.track(event: WooAnalyticsEvent.IssueRefund.quantityDialogOpened(orderID: state.order.orderID))
    }

    /// Tracks when the user taps the "select all" button
    ///
    private func trackSelectAllButtonTapped() {
        analytics.track(event: WooAnalyticsEvent.IssueRefund.selectAllButtonTapped(orderID: state.order.orderID))
    }
}


// MARK: Results Controller
private extension IssueRefundViewModel {

    /// Results controller that fetches the products related to this order
    ///
    func createProductsResultsController() -> ResultsController<StorageProduct> {
        let itemsIDs = state.itemsToRefund.map { $0.item.productID }
        let predicate = NSPredicate(format: "siteID == %lld AND productID IN %@", state.order.siteID, itemsIDs)
        return ResultsController<StorageProduct>(storageManager: ServiceLocator.storageManager, matching: predicate, sortedBy: [])
    }

    /// Results controller that fetches the payment gateway used on this order.
    ///
    func createPaymentGatewayResultsController() -> ResultsController<StoragePaymentGateway> {
        let predicate = NSPredicate(format: "siteID == %lld AND gatewayID == %@", state.order.siteID, state.order.paymentMethodID)
        return ResultsController<StoragePaymentGateway>(storageManager: ServiceLocator.storageManager, matching: predicate, sortedBy: [])
    }
}

// MARK: Constants
extension IssueRefundViewModel {
    enum Localization {
        static let refundShippingTitle = NSLocalizedString("Refund Shipping", comment: "Title of the switch in the IssueRefund screen to refund shipping")
        static let refundFeesTitle = NSLocalizedString(
            "Refund Fees", comment: "Title of the switch in the IssueRefund screen to refund fees")
        static let itemSingular = NSLocalizedString("1 item selected", comment: "Title of the label indicating that there is 1 item to refund.")
        static let itemsPlural = NSLocalizedString("%d items selected", comment: "Title of the label indicating that there are multiple items to refund.")
        static let unsupportedFeesRefund = NSLocalizedString(
            "You can refund fees in your store admin",
            comment: "Shown in Refunds screen. Refunding fees are currently not supported.")
    }
}

// MARK: Sections and Rows

/// Protocol that any `Section` item  should conform to.
///
protocol IssueRefundRow {}

extension IssueRefundViewModel {

    struct Section {
        let rows: [IssueRefundRow]
    }

    /// ViewModel that represents the shipping switch row.
    struct ShippingSwitchViewModel: IssueRefundRow {
        let title: String
        let isOn: Bool
    }

    /// ViewModel that represents the fees switch row.
    struct FeesSwitchViewModel: IssueRefundRow {
        let title: String
        let isOn: Bool
    }

    /// Creates sections for the table view to display
    ///
    private func createSections() -> [Section] {
        [
            createItemsToRefundSection(),
            createShippingSection(),
            createFeesSection()
        ].compactMap { $0 }
    }

    /// Returns a section with the order items that can be refunded
    ///
    private func createItemsToRefundSection() -> Section {
        let itemsRows = state.itemsToRefund.map { refundable -> RefundItemViewModel in
            let product = products.filter { $0.productID == refundable.item.productID }.first
            return RefundItemViewModel(refundable: refundable,
                                       product: product,
                                       refundQuantity: state.refundQuantityStore.refundQuantity(for: refundable.item),
                                       currency: state.order.currency,
                                       currencySettings: state.currencySettings)
        }

        let refundItems = state.refundQuantityStore.refundableItems()
        let summaryRow = RefundProductsTotalViewModel(refundItems: refundItems, currency: state.order.currency, currencySettings: state.currencySettings)

        return Section(rows: itemsRows + [summaryRow])
    }

    /// Returns a `Section` with the shipping switch row and the shipping details row.
    /// Returns `nil` if there isn't any shipping line available
    ///
    private func createShippingSection() -> Section? {
        // If there is no shipping cost to refund or shipping has already been refunded, then hide the section.
        guard let shippingLine = state.order.shippingLines.first, hasShippingBeenRefunded() == false else {
            return nil
        }

        // If there is no amount to refund (EG: free shipping), hide the refund shipping section
        let formatter = CurrencyFormatter(currencySettings: state.currencySettings)
        let shippingValues = RefundShippingCalculationUseCase(shippingLine: shippingLine, currencyFormatter: formatter)
        guard shippingValues.calculateRefundValue() > 0 else {
            return nil
        }

        // If `shouldRefundShipping` is disabled, return only the `switchRow`
        let switchRow = ShippingSwitchViewModel(title: Localization.refundShippingTitle, isOn: state.shouldRefundShipping)
        guard state.shouldRefundShipping else {
            return Section(rows: [switchRow])
        }

        let detailsRow = RefundShippingDetailsViewModel(shippingLine: shippingLine, currency: state.order.currency, currencySettings: state.currencySettings)
        return Section(rows: [switchRow, detailsRow])
    }

    private func createFeesSection() -> Section? {
        guard ServiceLocator.featureFlagService.isFeatureFlagEnabled(.refundFees), isAnyFeeAvailableForRefund() else {
                    return nil
                }

        let switchRow = FeesSwitchViewModel(title: Localization.refundFeesTitle, isOn: state.shouldRefundFees)
        guard state.shouldRefundFees else {
            return Section(rows: [switchRow])
        }

        let detailsRow = RefundFeesDetailsViewModel(fees: state.order.fees,
                                                    currency: state.order.currency,
                                                    currencySettings: state.currencySettings)

        return Section(rows: [switchRow, detailsRow])
    }

    /// Returns a string of the refund total formatted with the proper currency settings and store currency.
    ///
    private func calculateTitle() -> String {
        let formatter = CurrencyFormatter(currencySettings: state.currencySettings)
        let totalToRefund = calculateRefundTotal()
        return formatter.formatAmount(totalToRefund, with: state.order.currency) ?? ""
    }

    /// Returns the total amount to refund. ProductsTotal + Shipping Total(If required)
    ///
    private func calculateRefundTotal() -> Decimal {
        let formatter = CurrencyFormatter(currencySettings: state.currencySettings)
        let refundItems = state.refundQuantityStore.refundableItems()
        let productsTotalUseCase = RefundItemsValuesCalculationUseCase(refundItems: refundItems, currencyFormatter: formatter)

        var refundsTotal = productsTotalUseCase.calculateRefundValues().total

        // If shipping is enabled, sum the refund value to the total
        if let shippingLine = state.order.shippingLines.first, state.shouldRefundShipping {
            refundsTotal += RefundShippingCalculationUseCase(shippingLine: shippingLine, currencyFormatter: formatter).calculateRefundValue()
        }

        // If fees are enabled, sum the refund value to the total
        if state.shouldRefundFees {
            refundsTotal += RefundFeesCalculationUseCase(fees: state.order.fees, currencyFormatter: formatter).calculateRefundValues().total
        }

        return refundsTotal
    }

    /// Returns a string with the count of how many items are selected for refund.
    ///
    private func createSelectedItemsCount() -> String {
        let count = state.refundQuantityStore.count()
        return String.pluralize(count, singular: Localization.itemSingular, plural: Localization.itemsPlural)
    }

    /// Calculates wether the next button should be enabled or not
    ///
    private func calculateNextButtonEnableState() -> Bool {
        calculatePendingChangesState()
    }

    /// Calculates wether there are pending changes to commit
    ///
    private func calculatePendingChangesState() -> Bool {
        state.refundQuantityStore.count() > 0 || state.shouldRefundShipping || state.shouldRefundFees
    }

    /// Calculates wether the "select all" button should be visible or not.
    ///
    private func calculateSelectAllButtonVisibility() -> Bool {
        return state.itemsToRefund.isNotEmpty
    }

    /// Returns `true` if a shipping refund is found.
    /// Returns `false`if a shipping refund is not found.
    /// Returns `nil` if we don't have shipping refund information.
    /// - Discussion: Since we don't support partial refunds, we assume that any refund is a full refund for shipping costs.
    ///
    private func hasShippingBeenRefunded() -> Bool? {
        // Return false if there are no refunds.
        guard state.refunds.isNotEmpty else {
            return false
        }

        // Return nil if we can't get shipping line refunds information
        guard state.refunds.first?.shippingLines != nil else {
            return nil
        }

        // Return true if there is any non-empty shipping refund
        return state.refunds.first { $0.shippingLines?.isNotEmpty ?? false } != nil
    }

    private func isAnyFeeAvailableForRefund() -> Bool {
        // Return false if there are no fees left to be refunded.
        return state.order.fees.isEmpty
    }

    /// Return an array of `RefundableOrderItems` by taking out all previously refunded items
    ///
    private static func filterItems(from order: Order, with refunds: [Refund]) -> [RefundableOrderItem] {
        // Flattened array with all items refunded
        let allRefundedItems = refunds.flatMap { $0.items }

        // Transform `order.items` by subtracting the quantity left to refund and evicting those who were fully refunded.
        return order.items.compactMap { item -> RefundableOrderItem? in

            // Calculate how many times an item has been refunded. This number is negative.
            let timesRefunded = allRefundedItems.reduce(0) { timesRefunded, refundedItem -> Decimal in

                // Only keep accumulating if the refunded item product and the original item product match
                guard refundedItem.productOrVariationID == item.productOrVariationID else {
                    return timesRefunded
                }
                return timesRefunded + refundedItem.quantity
            }

            // If there is no more items to refund, evict it from the resulting array
            let quantityLeftToRefund = item.quantity + timesRefunded
            guard quantityLeftToRefund > 0 else {
                return nil
            }

            // Return the item with the updated quantity to refund
            return RefundableOrderItem(item: item, quantity: quantityLeftToRefund)
        }
    }
}

extension RefundItemViewModel: IssueRefundRow {}

extension RefundProductsTotalViewModel: IssueRefundRow {}

extension RefundShippingDetailsViewModel: IssueRefundRow {}

extension RefundFeesDetailsViewModel: IssueRefundRow {}

extension ImageAndTitleAndTextTableViewCell.ViewModel: IssueRefundRow {}

// MARK: Refund Quantity Store
private extension IssueRefundViewModel {
    /// Structure that holds and provides the quantity of items to refund
    ///
    struct RefundQuantityStore {
        typealias Quantity = Int

        /// Key: order item
        /// Value: quantity to refund
        ///
        private var store: [OrderItem: Quantity] = [:]

        /// Returns the quantity set to be refunded for an itemID
        ///
        func refundQuantity(for item: OrderItem) -> Quantity {
            store[item] ?? 0
        }

        /// Updates the quantity to be refunded for an itemID
        ///
        mutating func update(quantity: Quantity, for item: OrderItem) {
            store[item] = quantity
        }

        /// Returns an array containing the results of mapping the given closure over the sequence's elements.
        ///
        func map<T>(transform: (_ item: OrderItem, _ quantity: Quantity) -> (T)) -> [T] {
            store.map(transform)
        }

        /// Returns the number of items referenced for refund.
        /// Calculated by aggregating all stored quantities.
        ///
        func count() -> Int {
            store.values.reduce(0) { $0 + $1 }
        }

        /// Returns an array of `RefundableOrderItem` from the internal store
        ///
        func refundableItems() -> [RefundableOrderItem] {
            map { RefundableOrderItem(item: $0, quantity: $1) }
        }
    }
}
