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

        /// Current currency settings
        ///
        let currencySettings: CurrencySettings

        /// Bool indicating if shipping will be refunded
        ///
        var shouldRefundShipping: Bool = false

        /// Dictionary that holds the quantity of items to refund
        /// Key: item ID
        /// Value: quantity to refund
        ///
        typealias ItemID = Int64
        var refundQuantityStore: [ItemID: Int] = [:]
    }

    /// Current ViewModel state
    ///
    private var state: State {
        didSet {
            sections = createSections()
            onChange?()
        }
    }

    /// Title for the navigation bar
    /// This is temporary data, will be removed after implementing https://github.com/woocommerce/woocommerce-ios/issues/2842
    ///
    let title: String = "$0.00"

    /// String indicating how many items the user has selected to refund
    /// This is temporary data, will be removed after implementing https://github.com/woocommerce/woocommerce-ios/issues/2842
    ///
    let selectedItemsTitle: String = "0 items selected"

    /// Closured to notify the `ViewController` when the view model properties change
    ///
    var onChange: (() -> (Void))?

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

    init(order: Order, currencySettings: CurrencySettings) {
        state = State(order: order, currencySettings: currencySettings)
        sections = createSections()
    }
}

// MARK: User Actions
extension IssueRefundViewModel {
    /// Toggles the refund shipping state
    ///
    func toggleRefundShipping() {
        state.shouldRefundShipping.toggle()
    }

    /// Returns the number of items available for refund for the provided item index.
    /// Returns `nil` if the index is out of bounds
    ///
    func quantityAvailableForRefundForItemAtIndex(_ itemIndex: Int) -> Int? {
        guard let item = state.order.items[safe: itemIndex] else {
            return nil
        }
        return Int(truncating: item.quantity as NSDecimalNumber)
    }

    /// Returns the current quantlty set for refund for the provided item index.
    /// Returns `nil` if the index is out of bounds.
    ///
    func currentQuantityForItemAtIndex(_ itemIndex: Int) -> Int? {
        guard let item = state.order.items[safe: itemIndex] else {
            return nil
        }
        return state.refundQuantityStore[item.itemID] ?? 0
    }
}

// MARK: Results Controller
private extension IssueRefundViewModel {

    /// Results controller that fetches the products related to this order
    ///
    func createProductsResultsController() -> ResultsController<StorageProduct> {
        let itemsIDs = state.order.items.map { $0.productID }
        let predicate = NSPredicate(format: "siteID == %lld AND productID IN %@", state.order.siteID, itemsIDs)
        return ResultsController<StorageProduct>(storageManager: ServiceLocator.storageManager, matching: predicate, sortedBy: [])
    }
}

// MARK: Constants
private extension IssueRefundViewModel {
    enum Localization {
        static let refundShippingTitle = NSLocalizedString("Refund Shipping", comment: "Title of the switch in the IssueRefund screen to refund shipping")
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

    /// Creates sections for the table view to display
    ///
    private func createSections() -> [Section] {
        [
            createItemsToRefundSection(),
            createShippingSection()
        ].compactMap { $0 }
    }

    /// Returns a section with the order items that can be refunded
    ///
    private func createItemsToRefundSection() -> Section {
        let itemsRows = state.order.items.map { item -> RefundItemViewModel in
            let product = products.filter { $0.productID == item.productID }.first
            return RefundItemViewModel(item: item, product: product, currency: state.order.currency, currencySettings: state.currencySettings)
        }

        // This is temporary data, will be removed after implementing https://github.com/woocommerce/woocommerce-ios/issues/2842
        let summaryRow = RefundProductsTotalViewModel(productsTax: "$0.00", productsSubtotal: "$0.00", productsTotal: "$0.00")

        return Section(rows: itemsRows + [summaryRow])
    }

    /// Returns a `Section` with the shipping switch row and the shipping details row.
    /// Returns `nil` if there isn't any shipping line available
    ///
    private func createShippingSection() -> Section? {
        guard let shippingLine = state.order.shippingLines.first else {
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
}

extension RefundItemViewModel: IssueRefundRow {}

extension RefundProductsTotalViewModel: IssueRefundRow {}

extension RefundShippingDetailsViewModel: IssueRefundRow {}
