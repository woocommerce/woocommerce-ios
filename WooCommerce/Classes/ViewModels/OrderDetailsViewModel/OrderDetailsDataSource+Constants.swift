import Foundation
import Yosemite


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
}
