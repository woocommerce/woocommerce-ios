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
    private let hapticGenerator = UINotificationFeedbackGenerator()

    /// Sections to be rendered
    ///
    private(set) var sections = [Section]()

    /// Is this order processing?
    ///
    private var isProcessingPayment: Bool {
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
    private var summaryDateCreated: String {
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
    private var shippingLines: [ShippingLine] {
        return order.shippingLines
    }

    /// First Shipping method from an order
    ///
    private var shippingMethod: String {
        return shippingLines.first?.methodTitle ?? String()
    }

    /// All the items inside an order
    private var items: [OrderItem] {
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
    private var customerNote: String {
        return order.customerNote ?? String()
    }

    /// Computed Notes of an Order with note sections
    ///
    private var orderNotesSections: [NoteSection] = []

    private lazy var resultsControllers: OrderDetailsResultsControllers = {
        return OrderDetailsResultsControllers(order: self.order)
    }()

    private lazy var orderNoteAsyncDictionary: AsyncDictionary<Int, String> = {
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

// MARK: - Support for UITableViewDataSource
private extension OrderDetailsDataSource {
    func configure(_ cell: UITableViewCell, for row: Row, at indexPath: IndexPath) {
        switch cell {
        case let cell as WooBasicTableViewCell where row == .details:
            configureDetails(cell: cell)
        case let cell as CustomerInfoTableViewCell where row == .shippingAddress:
            configureShippingAddress(cell: cell)
        case let cell as CustomerNoteTableViewCell where row == .customerNote:
            configureCustomerNote(cell: cell)
        case let cell as CustomerNoteTableViewCell where row == .shippingMethod:
            configureShippingMethod(cell: cell)
        case let cell as WooBasicTableViewCell where row == .billingDetail:
            configureBillingDetail(cell: cell)
        case let cell as TopLeftImageTableViewCell where row == .shippingNotice:
            configureShippingNotice(cell: cell)
        case let cell as LeftImageTableViewCell where row == .addOrderNote:
            configureNewNote(cell: cell)
        case let cell as OrderNoteHeaderTableViewCell:
            configureOrderNoteHeader(cell: cell, at: indexPath)
        case let cell as OrderNoteTableViewCell:
            configureOrderNote(cell: cell, at: indexPath)
        case let cell as PaymentTableViewCell:
            configurePayment(cell: cell)
        case let cell as TwoColumnHeadlineFootnoteTableViewCell where row == .customerPaid:
            configureCustomerPaid(cell: cell)
        case let cell as TwoColumnHeadlineFootnoteTableViewCell where row == .refund:
            configureRefund(cell: cell, at: indexPath)
        case let cell as TwoColumnHeadlineFootnoteTableViewCell where row == .netAmount:
            configureNetAmount(cell: cell)
        case let cell as ProductDetailsTableViewCell:
            configureOrderItem(cell: cell, at: indexPath)
        case let cell as FulfillButtonTableViewCell:
            configureFulfillmentButton(cell: cell)
        case let cell as OrderTrackingTableViewCell:
            configureTracking(cell: cell, at: indexPath)
        case let cell as LeftImageTableViewCell where row == .trackingAdd:
            configureNewTracking(cell: cell)
        case let cell as SummaryTableViewCell:
            configureSummary(cell: cell)
        default:
            fatalError("Unidentified customer info row type")
        }
    }

    private func configureCustomerNote(cell: CustomerNoteTableViewCell) {
        cell.headline = Title.customerNote
        let localizedBody = String.localizedStringWithFormat(
            NSLocalizedString("“%@”",
                              comment: "Customer note, wrapped in quotes"),
            customerNote)
        cell.body = localizedBody
        cell.selectionStyle = .none
    }

    private func configureBillingDetail(cell: WooBasicTableViewCell) {
        cell.bodyLabel?.text = Footer.showBilling
        cell.bodyLabel?.applyBodyStyle()
        cell.accessoryType = .disclosureIndicator
        cell.selectionStyle = .default

        cell.accessibilityTraits = .button
        cell.accessibilityLabel = NSLocalizedString(
            "View Billing Information",
            comment: "Accessibility label for the 'View Billing Information' button"
        )

        cell.accessibilityHint = NSLocalizedString(
            "Show the billing details for this order.",
            comment: "VoiceOver accessibility hint, informing the user that the button can be used to view billing information."
        )
    }

    private func configureShippingNotice(cell: TopLeftImageTableViewCell) {
        let cellTextContent = NSLocalizedString(
            "This order is using extensions to calculate shipping. The shipping methods shown might be incomplete.",
            comment: "Shipping notice row label when there is more than one shipping method")
        cell.imageView?.image = Icons.shippingNoticeIcon
        cell.imageView?.tintColor = .accent
        cell.textLabel?.text = cellTextContent
        cell.selectionStyle = .none

        cell.accessibilityTraits = .staticText
        cell.accessibilityLabel = NSLocalizedString(
            "This order is using extensions to calculate shipping. The shipping methods shown might be incomplete.",
            comment: "Accessibility label for the Shipping notice")
        cell.accessibilityHint = NSLocalizedString("Shipping notice about the order",
                                                    comment: "VoiceOver accessibility label for the shipping notice about the order")
    }

    private func configureNewNote(cell: LeftImageTableViewCell) {
        cell.leftImage = Icons.addNoteIcon
        cell.imageView?.tintColor = .accent
        cell.labelText = Titles.addNoteText

        cell.accessibilityTraits = .button
        cell.accessibilityLabel = NSLocalizedString(
            "Add a note",
            comment: "Accessibility label for the 'Add a note' button"
        )

        cell.accessibilityHint = NSLocalizedString(
            "Composes a new order note.",
            comment: "VoiceOver accessibility hint, informing the user that the button can be used to create a new order note."
        )
    }

    private func configureOrderNoteHeader(cell: OrderNoteHeaderTableViewCell, at indexPath: IndexPath) {
        guard let noteHeader = noteHeader(at: indexPath) else {
            return
        }

        cell.dateCreated = noteHeader.toString(dateStyle: .medium, timeStyle: .none)
    }

    private func configureOrderNote(cell: OrderNoteTableViewCell, at indexPath: IndexPath) {
        guard let note = note(at: indexPath) else {
            return
        }

        cell.isSystemAuthor = note.isSystemAuthor
        cell.isCustomerNote = note.isCustomerNote
        cell.author = note.author
        cell.dateCreated = note.dateCreated.toString(dateStyle: .none, timeStyle: .short)
        cell.contents = orderNoteAsyncDictionary.value(forKey: note.noteID)
    }

    private func configurePayment(cell: PaymentTableViewCell) {
        let paymentViewModel = OrderPaymentDetailsViewModel(order: order)
        cell.configure(with: paymentViewModel)
    }

    private func configureCustomerPaid(cell: TwoColumnHeadlineFootnoteTableViewCell) {
        let paymentViewModel = OrderPaymentDetailsViewModel(order: order)
        cell.leftText = Titles.paidByCustomer
        cell.rightText = paymentViewModel.paymentTotal
        cell.updateFootnoteText(paymentViewModel.paymentSummary)
    }

    private func configureDetails(cell: WooBasicTableViewCell) {
        cell.bodyLabel?.text = Titles.productDetails
        cell.bodyLabel?.applyBodyStyle()
        cell.accessoryImage = nil
        cell.accessoryType = .disclosureIndicator
        cell.selectionStyle = .default
    }

    private func configureRefund(cell: TwoColumnHeadlineFootnoteTableViewCell, at indexPath: IndexPath) {
        let index = indexPath.row - Constants.paymentCell - Constants.paidByCustomerCell
        let condensedRefund = condensedRefunds[index]
        let refund = lookUpRefund(by: condensedRefund.refundID)
        let paymentViewModel = OrderPaymentDetailsViewModel(order: order, refund: refund)

        cell.leftText = Titles.refunded
        cell.leftTextIsActive(true)
        cell.rightText = paymentViewModel.refundAmount
        cell.rightTextIsActive(true)
        cell.updateFootnoteText(paymentViewModel.refundSummary)

        cell.accessibilityTraits = .button
        cell.accessibilityLabel = NSLocalizedString(
            "View refund details",
            comment: "Accessibility label for the 'View details' refund button"
        )
        cell.accessibilityHint = NSLocalizedString(
            "Show refund details for this order.",
            comment: "VoiceOver accessibility hint, informing the user that the button can be used to view refund detail information."
        )
    }

    private func configureNetAmount(cell: TwoColumnHeadlineFootnoteTableViewCell) {
        let paymentViewModel = OrderPaymentDetailsViewModel(order: order)

        cell.leftText = Titles.netAmount
        cell.rightText = paymentViewModel.netAmount
        cell.hideFootnote()
    }

    private func configureOrderItem(cell: ProductDetailsTableViewCell, at indexPath: IndexPath) {
        let item = items[indexPath.row]
        let product = lookUpProduct(by: item.productID)
        let itemViewModel = OrderItemViewModel(item: item, currency: order.currency, product: product)
        cell.selectionStyle = .default
        cell.configure(item: itemViewModel)
    }

    private func configureFulfillmentButton(cell: FulfillButtonTableViewCell) {
        cell.fulfillButton.setTitle(Titles.fulfillTitle, for: .normal)
        cell.onFullfillTouchUp = { [weak self] in
            self?.onCellAction?(.fulfill, nil)
        }
    }

    private func configureTracking(cell: OrderTrackingTableViewCell, at indexPath: IndexPath) {
        guard let tracking = orderTracking(at: indexPath) else {
            return
        }

        cell.topText = tracking.trackingProvider
        cell.middleText = tracking.trackingNumber

        cell.onEllipsisTouchUp = { [weak self] in
            self?.onCellAction?(.tracking, indexPath)
        }

        if let dateShipped = tracking.dateShipped?.toString(dateStyle: .long, timeStyle: .none) {
            cell.bottomText = String.localizedStringWithFormat(
                NSLocalizedString("Shipped %@",
                                  comment: "Date an item was shipped"),
                dateShipped)
        } else {
            cell.bottomText = NSLocalizedString("Not shipped yet",
                                                comment: "Order details > tracking. " +
                " This is where the shipping date would normally display.")
        }
    }

    private func configureNewTracking(cell: LeftImageTableViewCell) {
        let cellTextContent = NSLocalizedString("Add Tracking", comment: "Add Tracking row label")
        cell.leftImage = .addOutlineImage
        cell.imageView?.tintColor = .accent
        cell.labelText = cellTextContent

        cell.accessibilityTraits = .button
        cell.accessibilityLabel = NSLocalizedString(
            "Add a tracking",
            comment: "Accessibility label for the 'Add a tracking' button"
        )

        cell.accessibilityHint = NSLocalizedString(
            "Adds tracking to an order.",
            comment: "VoiceOver accessibility hint, informing the user that the button can be used to add tracking to an order. Should end with a period."
        )
    }

    private func configureShippingAddress(cell: CustomerInfoTableViewCell) {
        let shippingAddress = order.shippingAddress

        cell.title = NSLocalizedString("Shipping details", comment: "Shipping title for customer info cell")
        cell.name = shippingAddress?.fullNameWithCompany
        cell.address = shippingAddress?.formattedPostalAddress ??
            NSLocalizedString(
                "No address specified.",
                comment: "Order details > customer info > shipping details. This is where the address would normally display."
        )
    }

    private func configureShippingMethod(cell: CustomerNoteTableViewCell) {
        cell.headline = NSLocalizedString("Shipping Method",
                                          comment: "Shipping method title for customer info cell")
        cell.body = shippingMethod
        cell.selectionStyle = .none
    }

    private func configureSummary(cell: SummaryTableViewCell) {
        cell.title = summaryTitle
        cell.dateCreated = summaryDateCreated
        cell.onEditTouchUp = { [weak self] in
            self?.onCellAction?(.summary, nil)
        }


        let status = lookUpOrderStatus(for: order)?.status ?? OrderStatusEnum(rawValue: order.statusKey)
        let statusName = lookUpOrderStatus(for: order)?.name ?? order.statusKey
        let presentation = SummaryTableViewCellPresentation(status: status, statusName: statusName)

        cell.display(presentation: presentation)
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


// MARK: - Sections
extension OrderDetailsDataSource {
    /// Setup: Sections
    ///
    /// CustomerInformation Behavior:
    /// When: Customer Note == nil          >>> Hide Customer Note
    /// When: Shipping == nil               >>> Display: Shipping = "No address specified"
    ///
    func reloadSections() {
        let summary = Section(row: .summary)

        let shippingNotice: Section? = {
            //Hide the shipping method warning if order contains only virtual products or if the order contains only one shipping method
            if isMultiShippingLinesAvailable(for: order) == false {
                return nil
            }

            return Section(title: nil, rightTitle: nil, footer: nil, rows: [.shippingNotice])
        }()

        let products: Section? = {
            guard items.isEmpty == false else {
                return nil
            }

            var rows: [Row] = Array(repeating: .orderItem, count: items.count)
            if isProcessingPayment {
                rows.append(.fulfillButton)
            } else {
                rows.append(.details)
            }

            return Section(title: Title.product, rightTitle: Title.quantity, rows: rows)
        }()

        let customerInformation: Section = {
            var rows: [Row] = []

            if customerNote.isEmpty == false {
                rows.append(.customerNote)
            }
            if order.shippingAddress != nil {
                rows.append(.shippingAddress)
            }
            if shippingLines.count > 0 {
                rows.append(.shippingMethod)
            }
            rows.append(.billingDetail)

            return Section(title: Title.information, rows: rows)
        }()

        let payment: Section = {
            var rows: [Row] = [.payment, .customerPaid]

            if ServiceLocator.featureFlagService.isFeatureFlagEnabled(. refunds) {
                if order.refunds.count > 0 {
                    let refunds = Array<Row>(repeating: .refund, count: order.refunds.count)
                    rows.append(contentsOf: refunds)
                    rows.append(.netAmount)
                }
            }

            return Section(title: Title.payment, rows: rows)
        }()

        let tracking: Section? = {
            guard orderTracking.count > 0 else {
                return nil
            }

            let rows: [Row] = Array(repeating: .tracking, count: orderTracking.count)
            return Section(title: Title.tracking, rows: rows)
        }()

        let addTracking: Section? = {
            // Hide the section if the shipment
            // tracking plugin is not installed
            guard trackingIsReachable else {
                return nil
            }

            let title = orderTracking.count == 0 ? NSLocalizedString("Optional Tracking Information", comment: "") : nil
            let row = Row.trackingAdd

            return Section(title: title, rightTitle: nil, rows: [row])
        }()

        let notes: Section = {
            let rows = [.addOrderNote] + orderNotesSections.map {$0.row}
            return Section(title: Title.notes, rows: rows)
        }()

        sections = [summary, shippingNotice, products, customerInformation, payment, tracking, addTracking, notes].compactMap { $0 }
        updateOrderNoteAsyncDictionary(orderNotes: orderNotes)
    }

    private func updateOrderNoteAsyncDictionary(orderNotes: [OrderNote]) {
        orderNoteAsyncDictionary.clear()
        for orderNote in orderNotes {
            let calculation = { () -> (String) in
                return orderNote.note.strippedHTML
            }
            let onSet = { [weak self] (note: String?) -> () in
                guard note != nil else {
                    return
                }
                self?.onUIReloadRequired?()
            }
            orderNoteAsyncDictionary.calculate(forKey: orderNote.noteID,
                                               operation: calculation,
                                               onCompletion: onSet)
        }
    }

    func rowAtIndexPath(_ indexPath: IndexPath) -> Row {
        return sections[indexPath.section].rows[indexPath.row]
    }

    func noteHeader(at indexPath: IndexPath) -> Date? {
        // We need to subtract by one because the first order note row is the "Add Order" cell
        let noteHeaderIndex = indexPath.row - Constants.addOrderCell
        guard orderNotesSections.indices.contains(noteHeaderIndex) else {
            return nil
        }

        return orderNotesSections[noteHeaderIndex].date
    }

    func note(at indexPath: IndexPath) -> OrderNote? {
        // We need to subtract by one because the first order note row is the "Add Order" cell
        let noteIndex = indexPath.row - Constants.addOrderCell
        guard orderNotesSections.indices.contains(noteIndex) else {
            return nil
        }

        return orderNotesSections[noteIndex].orderNote
    }

    func orderTracking(at indexPath: IndexPath) -> ShipmentTracking? {
        let orderIndex = indexPath.row
        guard orderTracking.indices.contains(orderIndex) else {
            return nil
        }

        return orderTracking[orderIndex]
    }

    /// Sends the provided Row's text data to the pasteboard
    ///
    /// - Parameter indexPath: IndexPath to copy text data from
    ///
    func copyText(at indexPath: IndexPath) {
        let row = rowAtIndexPath(indexPath)

        switch row {
        case .shippingAddress:
            sendToPasteboard(order.shippingAddress?.fullNameWithCompanyAndAddress)
        case .tracking:
            sendToPasteboard(orderTracking(at: indexPath)?.trackingNumber, includeTrailingNewline: false)
        default:
            break // We only send text to the pasteboard from the address rows right meow
        }
    }

    /// Sends the provided text to the general pasteboard and triggers a success haptic. If the text param
    /// is nil, nothing is sent to the pasteboard.
    ///
    /// - Parameter
    ///   - text: string value to send to the pasteboard
    ///   - includeTrailingNewline: If true, insert a trailing newline; defaults to true
    ///
    func sendToPasteboard(_ text: String?, includeTrailingNewline: Bool = true) {
        guard var text = text, text.isEmpty == false else {
            return
        }

        if includeTrailingNewline {
            text += "\n"
        }

        UIPasteboard.general.string = text
        hapticGenerator.notificationOccurred(.success)
    }

    /// Checks if copying the row data at the provided indexPath is allowed
    ///
    /// - Parameter indexPath: index path of the row to check
    /// - Returns: true is copying is allowed, false otherwise
    ///
    func checkIfCopyingIsAllowed(for indexPath: IndexPath) -> Bool {
        let row = rowAtIndexPath(indexPath)
        switch row {
        case .shippingAddress:
            if let _ = order.shippingAddress {
                return true
            }
        case .tracking:
            if orderTracking(at: indexPath)?.trackingNumber.isEmpty == false {
                return true
            }
        default:
            break
        }

        return false
    }

    func computeOrderNotesSections() -> [NoteSection] {
        var sections: [NoteSection] = []

        for order in orderNotes {
            if sections.contains(where: { (section) -> Bool in
                return Calendar.current.isDate(section.date, inSameDayAs: order.dateCreated) && section.row == .orderNoteHeader
            }) {
                let orderToAppend = NoteSection(row: .orderNote, date: order.dateCreated, orderNote: order)
                sections.append(orderToAppend)
            }
            else {
                let sectionToAppend = NoteSection(row: .orderNoteHeader, date: order.dateCreated, orderNote: order)
                let orderToAppend = NoteSection(row: .orderNote, date: order.dateCreated, orderNote: order)
                sections.append(contentsOf: [sectionToAppend, orderToAppend])
            }
        }

        return sections
    }
}


// MARK: - Constants
extension OrderDetailsDataSource {
    enum Titles {
        static let productDetails = NSLocalizedString("Details",
                                                      comment: "The row label to tap for a detailed product list")
        static let fulfillTitle = NSLocalizedString("Begin Fulfillment",
                                                    comment: "Begin fulfill order button title")
        static let addNoteText = NSLocalizedString("Add a note",
                                                   comment: "Button text for adding a new order note")
        static let paidByCustomer = NSLocalizedString("Paid By Customer",
                                                      comment: "The title for the customer payment cell")
        static let refunded = NSLocalizedString("Refunded",
                                                comment: "The title for the refunded amount cell")
        static let netAmount = NSLocalizedString("Net", comment: "The title for the net amount paid cell")
    }

    enum Icons {
        static let addNoteIcon = UIImage.addOutlineImage
        static let shippingNoticeIcon = UIImage.noticeImage
    }

    enum Title {
        static let product = NSLocalizedString("Product", comment: "Product section title")
        static let quantity = NSLocalizedString("Qty", comment: "Quantity abbreviation for section title")
        static let tracking = NSLocalizedString("Tracking", comment: "Order tracking section title")
        static let customerNote = NSLocalizedString("Customer Provided Note", comment: "Customer note section title")
        static let information = NSLocalizedString("Customer", comment: "Customer info section title")
        static let payment = NSLocalizedString("Payment", comment: "Payment section title")
        static let notes = NSLocalizedString("Order Notes", comment: "Order notes section title")
    }

    enum Footer {
        static let showBilling = NSLocalizedString("View Billing Information",
                                                   comment: "Button on bottom of Customer's information to show the billing details")
    }

    struct Section {
        let title: String?
        let rightTitle: String?
        let footer: String?
        let rows: [Row]

        init(title: String? = nil, rightTitle: String? = nil, footer: String? = nil, rows: [Row]) {
            self.title = title
            self.rightTitle = rightTitle
            self.footer = footer
            self.rows = rows
        }

        init(title: String? = nil, rightTitle: String? = nil, footer: String? = nil, row: Row) {
            self.init(title: title, rightTitle: rightTitle, footer: footer, rows: [row])
        }
    }

    struct NoteSection {
        let row: Row
        let date: Date
        let orderNote: OrderNote

        init(row: Row, date: Date, orderNote: OrderNote) {
            self.row = row
            self.date = date
            self.orderNote = orderNote
        }
    }

    /// Rows listed in the order they appear on screen
    ///
    enum Row {
        case summary
        case orderItem
        case fulfillButton
        case details
        case customerNote
        case shippingAddress
        case shippingMethod
        case billingDetail
        case payment
        case customerPaid
        case refund
        case netAmount
        case tracking
        case trackingAdd
        case shippingNotice
        case addOrderNote
        case orderNoteHeader
        case orderNote

        var reuseIdentifier: String {
            switch self {
            case .summary:
                return SummaryTableViewCell.reuseIdentifier
            case .orderItem:
                return ProductDetailsTableViewCell.reuseIdentifier
            case .fulfillButton:
                return FulfillButtonTableViewCell.reuseIdentifier
            case .details:
                return WooBasicTableViewCell.reuseIdentifier
            case .customerNote:
                return CustomerNoteTableViewCell.reuseIdentifier
            case .shippingAddress:
                return CustomerInfoTableViewCell.reuseIdentifier
            case .shippingMethod:
                return CustomerNoteTableViewCell.reuseIdentifier
            case .billingDetail:
                return WooBasicTableViewCell.reuseIdentifier
            case .payment:
                return PaymentTableViewCell.reuseIdentifier
            case .customerPaid:
                return TwoColumnHeadlineFootnoteTableViewCell.reuseIdentifier
            case .refund:
                return TwoColumnHeadlineFootnoteTableViewCell.reuseIdentifier
            case .netAmount:
                return TwoColumnHeadlineFootnoteTableViewCell.reuseIdentifier
            case .tracking:
                return OrderTrackingTableViewCell.reuseIdentifier
            case .trackingAdd:
                return LeftImageTableViewCell.reuseIdentifier
            case .shippingNotice:
                return TopLeftImageTableViewCell.reuseIdentifier
            case .addOrderNote:
                return LeftImageTableViewCell.reuseIdentifier
            case .orderNoteHeader:
                return OrderNoteHeaderTableViewCell.reuseIdentifier
            case .orderNote:
                return OrderNoteTableViewCell.reuseIdentifier
            }
        }
    }

    enum CellActionType {
        case fulfill
        case tracking
        case summary
    }

    struct Constants {
        static let addOrderCell = 1
        static let paymentCell = 1
        static let paidByCustomerCell = 1
    }
}
