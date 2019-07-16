import Foundation
import UIKit
import Yosemite

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

    private var customerNote: String {
        return order.customerNote ?? String()
    }

    private var items: [OrderItem] {
        return order.items
    }

    private var isProcessingPayment: Bool {
        return order.statusKey == OrderStatusEnum.processing.rawValue
    }

    var displaysBillingDetails: Bool = false

    var trackingIsReachable: Bool = false

    private var subtotal: Decimal {
        let subtotal = order.items.reduce(Decimal(0)) { (output, item) in
            let itemSubtotal = Decimal(string: item.subtotal) ?? Decimal(0)
            return output + itemSubtotal
        }

        return subtotal
    }

    private var subtotalValue: String {
        let subAmount = NSDecimalNumber(decimal: subtotal).stringValue

        return CurrencyFormatter().formatAmount(subAmount, with: order.currency) ?? String()
    }

    /// Discounts
    /// - returns: 'Discount' label and a list of discount codes, or nil if zero.
    ///
    private var discountLabel: String? {
        return summarizeCoupons(from: couponLines)
    }

    private var discountValue: String? {
        guard let discount = currencyFormatter.convertToDecimal(from: order.discountTotal), discount.isZero() == false else {
            return nil
        }

        guard let formattedDiscount = currencyFormatter.formatAmount(order.discountTotal, with: order.currency) else {
            return nil
        }

        return "-" + formattedDiscount
    }

    private var shippingValue: String {
        return currencyFormatter.formatAmount(order.shippingTotal, with: order.currency) ?? String()
    }

    private var taxesValue: String? {
        return currencyFormatter.formatAmount(order.totalTax, with: order.currency)
    }

    private var totalValue: String {
        return currencyFormatter.formatAmount(order.total, with: order.currency) ?? String()
    }

    /// Anything above 999.99 or below -999.99 should display a truncated amount
    ///
    var totalFriendlyString: String? {
        return currencyFormatter.formatHumanReadableAmount(order.total, with: order.currency, roundSmallNumbers: false) ?? String()
    }

    /// Payment Summary
    /// - returns: A full sentence summary of how much was paid and using what method.
    ///
    private var paymentSummary: String? {
        if order.paymentMethodTitle.isEmpty {
            return nil
        }

        return NSLocalizedString(
            "Payment of \(totalValue) received via \(order.paymentMethodTitle)",
            comment: "Payment of <currency symbol><payment total> received via (payment method title)"
        )
    }

    private func summarizeCoupons(from lines: [OrderCouponLine]?) -> String? {
        guard let couponLines = lines else {
            return nil
        }

        let output = couponLines.reduce("") { (output, line) in
            let prefix = output.isEmpty ? "" : ","
            return output + prefix + line.code
        }

        guard !output.isEmpty else {
            return nil
        }

        return NSLocalizedString("Discount", comment: "Discount label for payment view") + " (" + output + ")"
    }

    var summaryTitle: String? {
        if let billingAddress = order.billingAddress {
            return "#\(order.number) \(billingAddress.firstName) \(billingAddress.lastName)"
        }
        return "#\(order.number)"
    }

    private var summaryDateCreated: String {
        return order.dateModified.relativelyFormattedUpdateString
    }


    var onCellAction: ((CellActionType, IndexPath?) -> Void)?

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

    var orderNotes: [OrderNote] = []

    private lazy var resultsControllers: OrderDetailsResultsControllers = {
        return OrderDetailsResultsControllers(order: self.order)
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

    func heightForFooterInSection(_ section: Int) -> CGFloat {
        let lastSectionIndex = sections.count - 1

        if sections[section].footer != nil || section == lastSectionIndex {
            return UITableView.automaticDimension
        }

        return .leastNonzeroMagnitude
    }

    func viewForFooterInSection(_ section: Int, tableView: UITableView) -> UIView? {
        guard let footerText = sections[section].footer else {
            return nil
        }

        let cell = tableView.dequeueReusableHeaderFooterView(withIdentifier: ShowHideSectionFooter.reuseIdentifier) as! ShowHideSectionFooter
        let image = displaysBillingDetails ? UIImage.chevronUpImage : UIImage.chevronDownImage
        cell.configure(text: footerText, image: image)
        cell.didSelectFooter = { [weak self] in
            guard let self = self else {
                return
            }

            let sections = IndexSet(integer: section)
            self.onCellAction?(.footer, nil)
            tableView.reloadSections(sections, with: .fade)
        }

        return cell
    }
}

// MARK: - Support for UITableViewDataSource
private extension OrderDetailsDataSource {
    func configure(_ cell: UITableViewCell, for row: Row, at indexPath: IndexPath) {
        switch cell {
        case let cell as WooBasicTableViewCell where row == .details:
            configureDetails(cell: cell)
        case let cell as WooBasicTableViewCell where row == .billingEmail:
            configureBillingEmail(cell: cell)
        case let cell as WooBasicTableViewCell where row == .billingPhone:
            configureBillingPhone(cell: cell)
        case let cell as CustomerInfoTableViewCell where row == .billingAddress:
            configureBillingAddress(cell: cell)
        case let cell as CustomerInfoTableViewCell where row == .shippingAddress:
            configureShippingAddress(cell: cell)
        case let cell as CustomerNoteTableViewCell:
            configureCustomerNote(cell: cell)
        case let cell as LeftImageTableViewCell where row == .addOrderNote:
            configureNewNote(cell: cell)
        case let cell as OrderNoteTableViewCell:
            configureOrderNote(cell: cell, at: indexPath)
        case let cell as PaymentTableViewCell:
            configurePayment(cell: cell)
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

    func configureBillingAddress(cell: CustomerInfoTableViewCell) {
        let billingAddress = order.billingAddress

        cell.title = NSLocalizedString("Billing details", comment: "Billing title for customer info cell")
        cell.name = billingAddress?.fullNameWithCompany
        cell.address = billingAddress?.formattedPostalAddress ??
            NSLocalizedString("No address specified.",
                              comment: "Order details > customer info > billing details. This is where the address would normally display.")
    }

    func configureBillingEmail(cell: WooBasicTableViewCell) {
        guard let email = order.billingAddress?.email else {
            return
        }

        cell.bodyLabel?.text = email
        cell.bodyLabel?.applyBodyStyle()
        cell.accessoryImage = .mailImage

        cell.isAccessibilityElement = true
        cell.accessibilityTraits = .button
        cell.accessibilityLabel = String.localizedStringWithFormat(
            NSLocalizedString("Email: %@",
                              comment: "Accessibility label that lets the user know the billing customer's email address"),
            email
        )

        cell.accessibilityHint = NSLocalizedString(
            "Composes a new email message to the billing customer.",
            comment: "Accessibility hint, informing that a row can be tapped and an email composer view will appear."
        )
    }

    func configureBillingPhone(cell: WooBasicTableViewCell) {
        guard let phoneNumber = order.billingAddress?.phone else {
            return
        }

        cell.bodyLabel?.text = phoneNumber
        cell.bodyLabel?.applyBodyStyle()
        cell.accessoryImage = .ellipsisImage

        cell.isAccessibilityElement = true
        cell.accessibilityTraits = .button
        cell.accessibilityLabel = String.localizedStringWithFormat(
            NSLocalizedString(
                "Phone number: %@",
                comment: "Accessibility label that lets the user know the data is a phone number before speaking the phone number."
            ),
            phoneNumber
        )

        cell.accessibilityHint = NSLocalizedString(
            "Prompts with the option to call or message the billing customer.",
            comment: "VoiceOver accessibility hint, informing the user that the row can be tapped to call or message the billing customer."
        )
    }

    func configureCustomerNote(cell: CustomerNoteTableViewCell) {
        cell.quote = customerNote
    }

    func configureNewNote(cell: LeftImageTableViewCell) {
        cell.leftImage = Icons.addNoteIcon
        cell.labelText = Titles.addNoteText

        cell.accessibilityTraits = .button
        cell.accessibilityLabel = NSLocalizedString(
            "Add a note button",
            comment: "Accessibility label for the 'Add a note' button"
        )

        cell.accessibilityHint = NSLocalizedString(
            "Composes a new order note.",
            comment: "VoiceOver accessibility hint, informing the user that the button can be used to create a new order note."
        )
    }

    func configureOrderNote(cell: OrderNoteTableViewCell, at indexPath: IndexPath) {
        guard let note = note(at: indexPath) else {
            return
        }

        cell.isSystemAuthor = note.isSystemAuthor
        cell.isCustomerNote = note.isCustomerNote
        cell.dateCreated = note.dateCreated.toString(dateStyle: .long, timeStyle: .short)
        cell.contents = note.note.strippedHTML
    }

    func configurePayment(cell: PaymentTableViewCell) {
        cell.subtotalLabel.text = Titles.subtotalLabel
        cell.subtotalValue.text = subtotalValue

        cell.discountLabel.text = discountLabel
        cell.discountValue.text = discountValue
        cell.discountView.isHidden = discountValue == nil

        cell.shippingLabel.text = Titles.shippingLabel
        cell.shippingValue.text = shippingValue

        cell.taxesLabel.text = Titles.taxesLabel
        cell.taxesValue.text = taxesValue
        cell.taxesView.isHidden = taxesValue == nil

        cell.totalLabel.text = Titles.totalLabel
        cell.totalValue.text = totalValue

        cell.footerText = paymentSummary

        cell.accessibilityElements = [cell.subtotalLabel as Any,
                                      cell.subtotalValue as Any,
                                      cell.discountLabel as Any,
                                      cell.discountValue as Any,
                                      cell.shippingLabel as Any,
                                      cell.shippingValue as Any,
                                      cell.taxesLabel as Any,
                                      cell.taxesValue as Any,
                                      cell.totalLabel as Any,
                                      cell.totalValue as Any]

        if let footerText = cell.footerText {
            cell.accessibilityElements?.append(footerText)
        }
    }

    func configureDetails(cell: WooBasicTableViewCell) {
        cell.bodyLabel?.text = Titles.productDetails
        cell.bodyLabel?.applyBodyStyle()
        cell.accessoryType = .disclosureIndicator
        cell.selectionStyle = .default
    }

    func configureOrderItem(cell: ProductDetailsTableViewCell, at indexPath: IndexPath) {
        let item = items[indexPath.row]
        let product = lookUpProduct(by: item.productID)
        let itemViewModel = OrderItemViewModel(item: item, currency: order.currency, product: product)
        cell.selectionStyle = .default
        cell.configure(item: itemViewModel)
    }

    func configureFulfillmentButton(cell: FulfillButtonTableViewCell) {
        cell.fulfillButton.setTitle(Titles.fulfillTitle, for: .normal)
        cell.onFullfillTouchUp = { [weak self] in
            self?.onCellAction?(.fulfill, nil)
        }
    }

    func configureTracking(cell: OrderTrackingTableViewCell, at indexPath: IndexPath) {
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

    func configureNewTracking(cell: LeftImageTableViewCell) {
        let cellTextContent = NSLocalizedString("Add Tracking", comment: "Add Tracking row label")
        cell.leftImage = .addOutlineImage
        cell.labelText = cellTextContent

        cell.accessibilityTraits = .button
        cell.accessibilityLabel = NSLocalizedString(
            "Add a tracking button",
            comment: "Accessibility label for the 'Add a tracking' button"
        )

        cell.accessibilityHint = NSLocalizedString(
            "Adds tracking to an order.",
            comment: "VoiceOver accessibility hint, informing the user that the button can be used to add tracking to an order. Should end with a period."
        )
    }

    func configureShippingAddress(cell: CustomerInfoTableViewCell) {
        let shippingAddress = order.shippingAddress

        cell.title = NSLocalizedString("Shipping details", comment: "Shipping title for customer info cell")
        cell.name = shippingAddress?.fullNameWithCompany
        cell.address = shippingAddress?.formattedPostalAddress ??
            NSLocalizedString(
                "No address specified.",
                comment: "Order details > customer info > shipping details. This is where the address would normally display."
        )
    }

    func configureSummary(cell: SummaryTableViewCell) {
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

}


// MARK: - Sections
extension OrderDetailsDataSource {
    /// Setup: Sections
    ///
    /// CustomerInformation Behavior:
    ///     When: Shipping == nil && Billing == nil     >>>     Display: Shipping = "No address specified" / Remove the rest
    ///     When: Shipping != nil && Billing == nil     >>>     Display: Shipping / Remove the rest
    ///     When: Shipping == nil && Billing != nil     >>>     Display: Shipping = "No address specified" / Billing / Footer
    ///     When: Shipping != nil && Billing != nil     >>>     Display: Shipping / Billing / Footer
    ///
    func reloadSections() {
        let summary = Section(row: .summary)

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

        let customerNotes: Section? = {
            guard customerNote.isEmpty == false else {
                return nil
            }

            return Section(title: Title.customerNote, row: .customerNote)
        }()

        let customerInformation: Section = {
            guard let address = order.billingAddress else {
                return Section(title: Title.information, row: .shippingAddress)
            }

            guard displaysBillingDetails else {
                return Section(title: Title.information, footer: Footer.showBilling, row: .shippingAddress)
            }

            var rows: [Row] = [.shippingAddress, .billingAddress]
            if address.hasPhoneNumber {
                rows.append(.billingPhone)
            }

            if address.hasEmailAddress {
                rows.append(.billingEmail)
            }

            return Section(title: Title.information, footer: Footer.hideBilling, rows: rows)
        }()

        let payment = Section(title: Title.payment, row: .payment)

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
            let rows = [.addOrderNote] + Array(repeating: Row.orderNote, count: orderNotes.count)
            return Section(title: Title.notes, rows: rows)
        }()

        sections = [summary, products, customerNotes, customerInformation, payment, tracking, addTracking, notes].compactMap { $0 }
    }

    private enum Title {
        static let product = NSLocalizedString("Product", comment: "Product section title")
        static let quantity = NSLocalizedString("Qty", comment: "Quantity abbreviation for section title")
        static let tracking = NSLocalizedString("Tracking", comment: "Order tracking section title")
        static let customerNote = NSLocalizedString("Customer Provided Note", comment: "Customer note section title")
        static let information = NSLocalizedString("Customer Information", comment: "Customer info section title")
        static let payment = NSLocalizedString("Payment", comment: "Payment section title")
        static let notes = NSLocalizedString("Order Notes", comment: "Order notes section title")
    }

    private enum Footer {
        static let hideBilling = NSLocalizedString("Hide billing", comment: "Footer text to hide the billing cell")
        static let showBilling = NSLocalizedString("Show billing", comment: "Footer text to show the billing cell")
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

    enum Row {
        case summary
        case fulfillButton
        case orderItem
        case details
        case tracking
        case trackingAdd
        case customerNote
        case shippingAddress
        case billingAddress
        case billingPhone
        case billingEmail
        case addOrderNote
        case orderNote
        case payment

        var reuseIdentifier: String {
            switch self {
            case .summary:
                return SummaryTableViewCell.reuseIdentifier
            case .fulfillButton:
                return FulfillButtonTableViewCell.reuseIdentifier
            case .orderItem:
                return ProductDetailsTableViewCell.reuseIdentifier
            case .details:
                return WooBasicTableViewCell.reuseIdentifier
            case .tracking:
                return OrderTrackingTableViewCell.reuseIdentifier
            case .trackingAdd:
                return LeftImageTableViewCell.reuseIdentifier
            case .customerNote:
                return CustomerNoteTableViewCell.reuseIdentifier
            case .shippingAddress:
                return CustomerInfoTableViewCell.reuseIdentifier
            case .billingAddress:
                return CustomerInfoTableViewCell.reuseIdentifier
            case .billingPhone:
                return WooBasicTableViewCell.reuseIdentifier
            case .billingEmail:
                return WooBasicTableViewCell.reuseIdentifier
            case .addOrderNote:
                return LeftImageTableViewCell.reuseIdentifier
            case .orderNote:
                return OrderNoteTableViewCell.reuseIdentifier
            case .payment:
                return PaymentTableViewCell.reuseIdentifier
            }
        }
    }

    enum CellActionType {
        case fulfill
        case tracking
        case summary
        case footer
    }

    func rowAtIndexPath(_ indexPath: IndexPath) -> Row {
        return sections[indexPath.section].rows[indexPath.row]
    }

    func note(at indexPath: IndexPath) -> OrderNote? {
        // We need to subtract 1 here because the first order note row is the "Add Order" cell
        let noteIndex = indexPath.row - 1
        guard orderNotes.indices.contains(noteIndex) else {
            return nil
        }

        return orderNotes[noteIndex]
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
        case .billingAddress:
            sendToPasteboard(order.billingAddress?.fullNameWithCompanyAndAddress)
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
    ///   - includeTrailingNewline: It true, insert a trailing newline; defaults to true
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
        case .billingAddress:
            if let _ = order.billingAddress {
                return true
            }
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
}


// MARK: - Constants
private extension OrderDetailsDataSource {
    enum Titles {
        static let productDetails = NSLocalizedString("Details",
                                                      comment: "The row label to tap for a detailed product list")
        static let fulfillTitle = NSLocalizedString("Fulfill order",
                                                    comment: "Fulfill order button title")
        static let subtotalLabel = NSLocalizedString("Subtotal",
                                                     comment: "Subtotal label for payment view")
        static let addNoteText = NSLocalizedString("Add a note",
                                                   comment: "Button text for adding a new order note")
        static let shippingLabel = NSLocalizedString("Shipping",
                                                     comment: "Shipping label for payment view")
        static let taxesLabel = NSLocalizedString("Taxes",
                                                  comment: "Taxes label for payment view")
        static let totalLabel = NSLocalizedString("Total",
                                                  comment: "Total label for payment view")
    }

    enum Icons {
        static let addNoteIcon = UIImage.addOutlineImage
    }
}
