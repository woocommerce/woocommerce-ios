import Foundation
import UIKit
import Yosemite


// MARK: - Support for UITableViewDataSource
/// Order Details: TableView Cell data.
///
extension OrderDetailsDataSource {
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
        case let cell as TwoColumnHeadlineAttributedFootnoteTableViewCell where row == .refund:
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
        cell.footnoteText = paymentViewModel.paymentSummary
    }

    private func configureDetails(cell: WooBasicTableViewCell) {
        cell.bodyLabel?.text = Titles.productDetails
        cell.bodyLabel?.applyBodyStyle()
        cell.accessoryImage = nil
        cell.accessoryType = .disclosureIndicator
        cell.selectionStyle = .default
    }

    private func configureRefund(cell: TwoColumnHeadlineAttributedFootnoteTableViewCell, at indexPath: IndexPath) {
//        let row = rowAtIndexPath(indexPath)
        let condensedRefund = condensedRefunds[indexPath.row - 2] // TODO-thuy: minus two should be constants
        let refund = lookUpRefund(by: condensedRefund.refundID)
        let paymentViewModel = OrderPaymentDetailsViewModel(order: order, refund: refund)
        cell.leftText = Titles.refunded
        cell.rightText = refund?.amount
        cell.footnoteAttributedText = paymentViewModel.refundSummary
    }

    private func configureNetAmount(cell: TwoColumnHeadlineFootnoteTableViewCell) {
        cell.leftText = Titles.netAmount
//        cell.rightText = viewModel.netAmount
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
