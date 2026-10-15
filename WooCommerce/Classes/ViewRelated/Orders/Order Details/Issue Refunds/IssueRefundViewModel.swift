import Foundation
import Yosemite
import WooFoundation
import protocol Storage.StorageManagerType

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
        var refunds: [Refund]

        /// Items to refund. Order Items - Refunded items
        ///
        var itemsToRefund: [RefundableOrderItem]

        var isLoadingRefunds = false
        var refundFetchFailed = false

        /// Current currency settings
        ///
        let currencySettings: CurrencySettings

        /// Bool indicating if shipping will be refunded
        ///
        var shouldRefundShipping: Bool = false

        /// Bool indicating if custom amounts will be refunded
        ///
        var shouldRefundCustomAmounts: Bool

        ///  Holds the quantity of items to refund
        ///
        var refundQuantityStore = RefundQuantityStore()

        /// Charge to be refunded
        ///
        var charge: WCPayCharge?

        /// Error from fetching refund charge.
        ///
        var fetchChargeError: FetchChargeError?
    }

    /// Current ViewModel state
    ///
    private var state: State {
        didSet {
            sections = createSections()
            title = calculateTitle()
            selectedItemsTitle = createSelectedItemsCount()
            isSelectAllButtonVisible = calculateSelectAllButtonVisibility()
            isNextButtonEnabled = calculateNextButtonEnableState()
            isNextButtonAnimating = calculateNextButtonAnimatingState()
            hasUnsavedChanges = calculatePendingChangesState()
            onChange?()
        }
    }

    /// Closure to notify the `ViewController` when the view model properties change
    ///
    var onChange: (() -> (Void))?

    /// This closure is executed when fetching the charge details failed.
    /// Implement the input parameter with a closure to be execured when the user wants to retry the fetch action.
    ///
    var showFetchChargeErrorNotice: ((@escaping (() -> Void)) -> (Void))?

    var showFetchRefundsErrorNotice: ((@escaping () -> Void) -> Void)?

    /// Title for the navigation bar
    ///
    private(set) var title: String = ""

    /// String indicating how many items the user has selected to refund
    ///
    private(set) var selectedItemsTitle: String = ""

    /// Boolean indicating if the next button is enabled
    ///
    private(set) var isNextButtonEnabled: Bool = false

    /// Boolean indicating if the next button's activity indicator is animating
    ///
    private(set) var isNextButtonAnimating: Bool = false

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

    /// Charge related to the order. Used to show card details in the `Refund Via` section, and the refund confirmation screen.
    ///
    private var charge: WCPayCharge? {
        chargeResultsController?.fetchedObjects.first
    }

    /// ResultsController for the charge relating to the order. Used to show card details in the `Refund Via` section, and the refund confirmation screen.
    ///
    private lazy var chargeResultsController: ResultsController<StorageWCPayCharge>? = {
        guard let resultsController = createWcPayChargeResultsController() else {
            return nil
        }
        try? resultsController.performFetch()
        return resultsController
    }()

    private let refundableOrderItemsDeterminer: OrderRefundsOptionsDeterminerProtocol

    private let analytics: Analytics

    private let stores: StoresManager

    private let storage: StorageManagerType

    init(order: Order,
         refunds: [Refund],
         currencySettings: CurrencySettings,
         analytics: Analytics = ServiceLocator.analytics,
         stores: StoresManager = ServiceLocator.stores,
         storage: StorageManagerType = ServiceLocator.storageManager,
         refundableOrderItemsDeterminer: OrderRefundsOptionsDeterminerProtocol = OrderRefundsOptionsDeterminer()) {
        self.refundableOrderItemsDeterminer = refundableOrderItemsDeterminer
        self.analytics = analytics
        self.stores = stores
        self.storage = storage
        let items = refundableOrderItemsDeterminer.determineRefundableOrderItems(from: order, with: refunds)
        state = State(order: order,
                      refunds: refunds,
                      itemsToRefund: items,
                      currencySettings: currencySettings,
                      shouldRefundCustomAmounts: refundableOrderItemsDeterminer.shouldRefundCustomAmountsByDefault(from: order),
                      charge: nil)
        sections = createSections()
        title = calculateTitle()
        isNextButtonEnabled = calculateNextButtonEnableState()
        isNextButtonAnimating = calculateNextButtonAnimatingState()
        isSelectAllButtonVisible = calculateSelectAllButtonVisibility()
        selectedItemsTitle = createSelectedItemsCount()
        hasUnsavedChanges = calculatePendingChangesState()
        observeCharge()
    }

    /// Creates the `ViewModel` to be used when navigating to the page where the user can
    /// confirm and submit the refund.
    func createRefundConfirmationViewModel(onCompletion: @escaping ((RefundConfirmationViewModel) -> Void)) {
        let action = CardPresentPaymentAction.selectedPaymentGatewayAccount { [weak self] paymentGatewayAccount in
            guard let self else { return }
            let details = RefundConfirmationViewModel.Details(order: self.state.order,
                                                              charge: self.state.charge,
                                                              amount: "\(self.calculateRefundTotal())",
                                                              refundsShipping: self.state.shouldRefundShipping,
                                                              refundsFees: self.state.shouldRefundCustomAmounts,
                                                              items: self.selectedItems(),
                                                              paymentGateway: self.paymentGateway,
                                                              paymentGatewayAccount: paymentGatewayAccount,
                                                              shippingLines: self.shippingLinesToRefund(),
                                                              fees: self.refundableFees())

            onCompletion(RefundConfirmationViewModel(details: details, currencySettings: self.state.currencySettings))
        }

        stores.dispatch(action)
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

    func toggleRefundCustomAmounts() {
        state.shouldRefundCustomAmounts.toggle()
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

    /// Fetches the necessary information to show the issue refund screen.
    ///
    func fetch() {
        fetchCharge()
        fetchRefunds()
    }

    private func fetchRefunds() {
        guard state.order.refunds.isNotEmpty else { return }
        state.isLoadingRefunds = true
        state.refundFetchFailed = false
        var fetched: [Refund] = []
        var outstanding = state.order.refunds.count
        for refundID in state.order.refunds.map(\.refundID) {
            stores.dispatch(RefundAction.retrieveRefund(siteID: state.order.siteID, orderID: state.order.orderID, refundID: refundID) {
                [weak self] refund, error in
                guard let self else { return }
                if let refund, error == nil { fetched.append(refund) } else { self.state.refundFetchFailed = true }
                outstanding -= 1
                guard outstanding == 0 else { return }
                if !self.state.refundFetchFailed {
                    self.state.refunds = fetched
                    self.state.itemsToRefund = self.refundableOrderItemsDeterminer.determineRefundableOrderItems(from: self.state.order, with: fetched)
                    var quantities = RefundQuantityStore()
                    for item in self.state.itemsToRefund {
                        quantities.update(quantity: min(self.state.refundQuantityStore.refundQuantity(for: item.item), item.quantity), for: item.item)
                    }
                    self.state.refundQuantityStore = quantities
                    if self.refundableShippingLines()?.isEmpty != false { self.state.shouldRefundShipping = false }
                    if self.refundableFees().isEmpty { self.state.shouldRefundCustomAmounts = false }
                }
                self.state.isLoadingRefunds = false
                if self.state.refundFetchFailed {
                    self.showFetchRefundsErrorNotice? { [weak self] in self?.fetchRefunds() }
                }
            })
        }
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
        return ResultsController<StorageProduct>(storageManager: storage, matching: predicate, sortedBy: [])
    }

    /// Results controller that fetches the payment gateway used on this order.
    ///
    func createPaymentGatewayResultsController() -> ResultsController<StoragePaymentGateway> {
        let predicate = NSPredicate(format: "siteID == %lld AND gatewayID == %@", state.order.siteID, state.order.paymentMethodID)
        return ResultsController<StoragePaymentGateway>(storageManager: storage, matching: predicate, sortedBy: [])
    }

    func createWcPayChargeResultsController() -> ResultsController<StorageWCPayCharge>? {
        guard let chargeID = state.order.chargeID,
              chargeID.isNotEmpty else {
            return nil
        }
        let predicate = NSPredicate(format: "siteID == %ld AND chargeID == %@", state.order.siteID, chargeID)
        return ResultsController<StorageWCPayCharge>(storageManager: storage, matching: predicate, sortedBy: [])
    }

    func observeCharge() {
        chargeResultsController?.onDidChangeContent = { [weak self] in
            guard let self else { return }
            self.state.charge = self.charge
        }
    }

    func fetchCharge() {
        guard let chargeID = state.order.chargeID else {
            return
        }

        state.fetchChargeError = nil

        let action = CardPresentPaymentAction.fetchWCPayCharge(siteID: state.order.siteID, chargeID: chargeID, onCompletion: { [weak self] result in
            if case .failure = result {
                self?.state.fetchChargeError = .requestError

                self?.showFetchChargeErrorNotice?({ [weak self] in
                    self?.fetchCharge()
                })
            }
        })

        stores.dispatch(action)
    }
}

// MARK: Constants
extension IssueRefundViewModel {
    enum Localization {
        static let refundShippingTitle = NSLocalizedString("Refund Shipping", comment: "Title of the switch in the IssueRefund screen to refund shipping")
        static let refundCustomAmountsTitle = NSLocalizedString("refundIssue.customAmounts.title",
                                                                value: "Refund Custom Amounts",
                                                                comment: "Title of the switch in the IssueRefund screen to refund customAmounts")
        static let itemSingular = NSLocalizedString("1 item selected", comment: "Title of the label indicating that there is 1 item to refund.")
        static let itemsPlural = NSLocalizedString("%d items selected", comment: "Title of the label indicating that there are multiple items to refund.")
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

    /// ViewModel that represents the customAmounts switch row.
    struct CustomAmountsSwitchViewModel: IssueRefundRow {
        let title: String
        let isOn: Bool
    }

    /// Creates sections for the table view to display
    ///
    private func createSections() -> [Section] {
        [
            createItemsToRefundSection(),
            createShippingSection(),
            createCustomAmountsSection()
        ].compactMap { $0 }
    }

    /// Returns a section with the order items that can be refunded
    ///
    private func createItemsToRefundSection() -> Section {
        let itemsRows = state.itemsToRefund.map { refundable -> RefundItemViewModel in
            let product = products.first(where: { $0.productID == refundable.item.productID })
            return RefundItemViewModel(refundable: refundable,
                                       product: product,
                                       refundQuantity: state.refundQuantityStore.refundQuantity(for: refundable.item),
                                       currency: state.order.currency,
                                       currencySettings: state.currencySettings)
        }

        let refundItems = selectedItems()
        let productIDs = Set(refundItems.map { $0.item.itemID })
        let summaryRow = RefundProductsTotalViewModel(refundItems: refundItems, currency: state.order.currency,
                                                    currencySettings: state.currencySettings,
                                                    allocatedLines: selectedRefundLines().filter { productIDs.contains($0.itemID) },
                                                    includesUnallocatedTax: calculateRefundTotal() == calculateUncappedRefundTotal())

        return Section(rows: itemsRows + [summaryRow])
    }

    /// Returns a `Section` with the shipping switch row and the shipping details row.
    /// Returns `nil` if there isn't any shipping line available
    ///
    private func createShippingSection() -> Section? {
        // If there is no shipping cost to refund or shipping has already been refunded, then hide the section.
        guard let shippingLines = refundableShippingLines(),
              shippingLines.isNotEmpty else {
            return nil
        }

        // If there is no amount to refund (EG: free shipping), hide the refund shipping section
        let formatter = CurrencyFormatter(currencySettings: state.currencySettings)
        let shippingValue = shippingLines.reduce(Decimal.zero) { partialResult, shippingLine in
            partialResult + RefundShippingCalculationUseCase(shippingLine: shippingLine, currencyFormatter: formatter).calculateRefundValue()
        }
        guard shippingValue > 0 else {
            return nil
        }

        // If `shouldRefundShipping` is disabled, return only the `switchRow`
        let switchRow = ShippingSwitchViewModel(title: Localization.refundShippingTitle, isOn: state.shouldRefundShipping)
        guard state.shouldRefundShipping else {
            return Section(rows: [switchRow])
        }

        let allocatedLines = selectedRefundLines()
        let isUncapped = calculateRefundTotal() == calculateUncappedRefundTotal()
        let detailsRows: [IssueRefundRow] = shippingLines.map { original in
            let line = allocatedLines.first { $0.itemID == original.shippingID }
            let shippingLine = line.map {
                if $0.taxes.isEmpty && isUncapped { return original }
                return original.copy(total: $0.total, totalTax: "\($0.taxes.reduce(Decimal.zero) { $0 + (Decimal(string: $1.total) ?? .zero) })")
            } ?? original.copy(total: "0", totalTax: "0", taxes: [])
            return RefundShippingDetailsViewModel(shippingLine: shippingLine, currency: state.order.currency, currencySettings: state.currencySettings)
        }
        return Section(rows: [switchRow as IssueRefundRow] + detailsRows)
    }

    private func createCustomAmountsSection() -> Section? {
        guard isAnyCustomAmountAvailableForRefund() else {
            return nil
        }

        let switchRow = CustomAmountsSwitchViewModel(title: Localization.refundCustomAmountsTitle, isOn: state.shouldRefundCustomAmounts)
        guard state.shouldRefundCustomAmounts else {
            return Section(rows: [switchRow])
        }

        let allocatedLines = selectedRefundLines()
        let isUncapped = calculateRefundTotal() == calculateUncappedRefundTotal()
        let allocatedFees = refundableFees().map { original in
            guard let line = allocatedLines.first(where: { $0.itemID == original.feeID }) else {
                return original.copy(total: "0", totalTax: "0", taxes: [])
            }
            if line.taxes.isEmpty && isUncapped { return original }
            return original.copy(total: line.total, totalTax: "\(line.taxes.reduce(Decimal.zero) { $0 + (Decimal(string: $1.total) ?? .zero) })",
                                 taxes: line.taxes.map { .init(taxID: $0.taxID, subtotal: "", total: $0.total) })
        }
        let detailsRow = RefundCustomAmountsDetailsViewModel(fees: allocatedFees,
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
        let total = calculateUncappedRefundTotal()
        let formatter = CurrencyFormatter(currencySettings: state.currencySettings)
        return min(total, calculateMaxRefundableAmount(with: formatter) ?? total)
    }

    private func calculateUncappedRefundTotal() -> Decimal {
        let formatter = CurrencyFormatter(currencySettings: state.currencySettings)
        let refundItems = selectedItems()
        let productsTotalUseCase = RefundItemsValuesCalculationUseCase(refundItems: refundItems, currencyFormatter: formatter,
                                                                      numberOfDecimals: state.currencySettings.fractionDigits)

        var refundsTotal = productsTotalUseCase.calculateRefundValues().total

        // If shipping is enabled, sum the refund value to the total
        if state.shouldRefundShipping {
            refundsTotal += shippingLinesToRefund().reduce(Decimal.zero) { partialResult, shippingLine in
                partialResult + RefundShippingCalculationUseCase(shippingLine: shippingLine, currencyFormatter: formatter).calculateRefundValue()
            }
        }

        // If customAmounts are enabled, sum the refund value to the total
        if state.shouldRefundCustomAmounts {
            refundsTotal += RefundFeesCalculationUseCase(fees: refundableFees(), currencyFormatter: formatter).calculateRefundValues().total
        }

        return refundsTotal
    }

    /// Returns the maximum amount that can still be refunded on the order:
    /// the order total minus the previously refunded totals. `nil` when the order total cannot be parsed.
    ///
    private func calculateMaxRefundableAmount(with formatter: CurrencyFormatter) -> Decimal? {
        guard let orderTotal = formatter.convertToDecimal(state.order.total) as Decimal? else {
            return nil
        }
        // `totalRefunded()` is a negative value.
        let totalRefunded = TotalRefundedCalculationUseCase(order: state.order, currencyFormatter: formatter).totalRefunded().decimalValue
        return max(orderTotal + totalRefunded, .zero)
    }

    /// Returns a string with the count of how many items are selected for refund.
    ///
    private func createSelectedItemsCount() -> String {
        let count = state.refundQuantityStore.count()
        return String.pluralize(count, singular: Localization.itemSingular, plural: Localization.itemsPlural)
    }

    /// Calculates whether the next button should be enabled or not
    ///
    private func calculateNextButtonEnableState() -> Bool {
        !state.isLoadingRefunds && !state.refundFetchFailed && calculatePendingChangesState() && calculateRefundTotal() >= 0
    }

    /// Calculates whether the next button should be animating or not
    ///
    private func calculateNextButtonAnimatingState() -> Bool {
        // When we have a chargeID, we need to wait until we fetch the charge unless there is an error fetching the charge.
        state.isLoadingRefunds || (state.charge == nil && !state.order.chargeID.isNilOrEmpty && state.fetchChargeError == nil)
    }

    /// Calculates whether there are pending changes to commit
    ///
    private func calculatePendingChangesState() -> Bool {
        guard state.fetchChargeError == nil else {
            return false
        }

        return state.refundQuantityStore.count() > 0
            || (state.shouldRefundShipping && shippingLinesToRefund().isNotEmpty)
            || (state.shouldRefundCustomAmounts && refundableFees().isNotEmpty)
    }

    /// Calculates whether the "select all" button should be visible or not.
    ///
    private func calculateSelectAllButtonVisibility() -> Bool {
        state.itemsToRefund.isNotEmpty
    }

    /// Returns shipping lines that can still be refunded.
    /// Returns `nil` if we don't have shipping refund information.
    ///
    private func refundableShippingLines() -> [ShippingLine]? {
        OrderRefundsOptionsDeterminer.remainingShipping(in: state.order, refunds: state.refunds)
    }

    private func shippingLinesToRefund() -> [ShippingLine] {
        guard state.shouldRefundShipping else {
            return []
        }
        return refundableShippingLines() ?? []
    }

    private func refundableFees() -> [OrderFeeLine] {
        OrderRefundsOptionsDeterminer.remainingFees(in: state.order, refunds: state.refunds)
    }

    private func selectedItems() -> [RefundableOrderItem] {
        state.itemsToRefund.map { $0.selecting(quantity: state.refundQuantityStore.refundQuantity(for: $0.item)) }
    }

    private func selectedRefundLines() -> [OrderItemRefund] {
        RefundCreationUseCase(amount: "\(calculateRefundTotal())", reason: nil, automaticallyRefundsPayment: false,
                              items: selectedItems(), shippingLines: shippingLinesToRefund(),
                              fees: state.shouldRefundCustomAmounts ? refundableFees() : [],
                              currencyFormatter: CurrencyFormatter(currencySettings: state.currencySettings),
                              numberOfDecimals: state.currencySettings.fractionDigits).createRefundItems()
    }

    private func isAnyCustomAmountAvailableForRefund() -> Bool {
        // Return false if there are no custom amounts left to be refunded.
        return refundableFees().isNotEmpty
    }
}

// MARK: Definitions
extension IssueRefundViewModel {
    /// Error from fetching refund charge details.
    enum FetchChargeError: Error, Equatable {
        case unknownPaymentGatewayAccount
        case requestError
    }
}

extension RefundItemViewModel: IssueRefundRow {}

extension RefundProductsTotalViewModel: IssueRefundRow {}

extension RefundShippingDetailsViewModel: IssueRefundRow {}

extension RefundCustomAmountsDetailsViewModel: IssueRefundRow {}

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

        /// Returns the number of items referenced for refund.
        /// Calculated by aggregating all stored quantities.
        ///
        func count() -> Int {
            store.values.reduce(0) { $0 + $1 }
        }
    }
}
