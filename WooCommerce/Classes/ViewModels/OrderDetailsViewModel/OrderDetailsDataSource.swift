import Foundation
import UIKit
import Yosemite


/// The main file for Order Details data.
///
final class OrderDetailsDataSource: NSObject {
    private(set) var order: Order
    private let currencyFormatter = CurrencyFormatter()
    private let couponLines: [OrderCouponLine]?

    /// Haptic Feedback!
    ///
    let hapticGenerator = UINotificationFeedbackGenerator()

    /// Sections to be rendered
    ///
    var sections = [Section]()

    /// Is this order processing?
    ///
    var isProcessingPayment: Bool {
        return order.statusKey == OrderStatusEnum.processing.rawValue
    }

    /// Is the shipment tracking plugin available?
    ///
    var trackingIsReachable: Bool = false

    /// Anything above 999.99 or below -999.99 should display a truncated amount
    ///
    var totalFriendlyString: String? {
        return currencyFormatter.formatHumanReadableAmount(order.total, with: order.currency, roundSmallNumbers: false) ?? String()
    }

    /// For example, #560 Pamela Nguyen
    ///
    var summaryTitle: String? {
        if let billingAddress = order.billingAddress {
            return "#\(order.number) \(billingAddress.firstName) \(billingAddress.lastName)"
        }
        return "#\(order.number)"
    }

    /// For example, Oct 1, 2019 at 2:31 PM
    ///
    var summaryDateCreated: String {
        return order.dateModified.relativelyFormattedUpdateString
    }

    /// Closure to be executed when the cell was tapped.
    ///
    var onCellAction: ((CellActionType, IndexPath?) -> Void)?

    /// Closure to be executed when the UI needs to be reloaded.
    ///
    var onUIReloadRequired: (() -> Void)?

    /// Order shipment tracking list
    ///
    var orderTracking: [ShipmentTracking] {
        return resultsControllers.orderTracking
    }

    /// Order statuses list
    ///
    var currentSiteStatuses: [OrderStatus] {
        return resultsControllers.currentSiteStatuses
    }

    /// Products from an Order
    ///
    var products: [Product] {
        return resultsControllers.products
    }

    /// Refunds on an Order
    ///
    var refunds: [Refund] {
        return resultsControllers.refunds
    }
    
    /// Shipping Lines from an Order
    ///
    var shippingLines: [ShippingLine] {
        return order.shippingLines
    }

    /// First Shipping method from an order
    ///
    var shippingMethod: String {
        return shippingLines.first?.methodTitle ?? String()
    }

    /// All the items inside an order
    var items: [OrderItem] {
        return order.items
    }

    /// All the condensed refunds in an order
    ///
    var condensedRefunds: [OrderRefundCondensed] {
        return order.refunds
    }

    /// Notes of an Order
    ///
    var orderNotes: [OrderNote] = [] {
        didSet {
            orderNotesSections = computeOrderNotesSections()
        }
    }

    /// Note of customer about the order
    var customerNote: String {
        return order.customerNote ?? String()
    }

    /// Computed Notes of an Order with note sections
    ///
    var orderNotesSections: [NoteSection] = []

    private lazy var resultsControllers: OrderDetailsResultsControllers = {
        return OrderDetailsResultsControllers(order: self.order)
    }()

    lazy var orderNoteAsyncDictionary: AsyncDictionary<Int, String> = {
        return AsyncDictionary()
    }()

    init(order: Order) {
        self.order = order
        self.couponLines = order.coupons
        super.init()
    }

    func update(order: Order) {
        self.order = order
    }

    func configureResultsControllers(onReload: @escaping () -> Void) {
        resultsControllers.configureResultsControllers(onReload: onReload)
    }
}


// MARK: - Conformance to UITableViewDataSource
extension OrderDetailsDataSource: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].rows.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = sections[indexPath.section].rows[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: row.reuseIdentifier, for: indexPath)
        configure(cell, for: row, at: indexPath)
        return cell
    }
}


// MARK: - Support for UITableViewDelegate
extension OrderDetailsDataSource {
    func viewForHeaderInSection(_ section: Int, tableView: UITableView) -> UIView? {
        guard let leftText = sections[section].title else {
            return nil
        }

        let headerID = TwoColumnSectionHeaderView.reuseIdentifier
        guard let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: headerID) as? TwoColumnSectionHeaderView else {
            fatalError()
        }

        headerView.leftText = leftText
        headerView.rightText = sections[section].rightTitle

        return headerView
    }
}


// MARK: - Lookup orders and statuses
extension OrderDetailsDataSource {
    func lookUpOrderStatus(for order: Order) -> OrderStatus? {
        return currentSiteStatuses.filter({$0.slug == order.statusKey}).first
    }

    func lookUpProduct(by productID: Int) -> Product? {
        return products.filter({ $0.productID == productID }).first
    }

    func lookUpRefund(by refundID: Int) -> Refund? {
        return refunds.filter({ $0.refundID == refundID }).first
    }

    func isMultiShippingLinesAvailable(for order: Order) -> Bool {
        return shippingLines.count > 1
    }
}
