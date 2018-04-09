import UIKit

class SingleOrderSummaryCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var createdLabel: UILabel!
    @IBOutlet weak var paymentLabel: PaddedLabel!

    static let reuseIdentifier = "SingleOrderSummaryCell"

    func configureCell(order: Order) {
        let titleString = "#\(order.number) \(order.shippingAddress.firstName) \(order.shippingAddress.lastName)"
        var paymentStatusText: String
        if order.status == .custom {
            paymentStatusText = order.statusString
        } else {
            paymentStatusText = order.status.description
        }
        let fuzzyDate = String.localizedStringWithFormat(NSLocalizedString("Created %@", comment: "Order created date"), order.dateCreatedString) // FIXME: needs fuzzy date

        titleLabel.text = titleString
        createdLabel.text = fuzzyDate
        paymentLabel.text = paymentStatusText

        titleLabel.applyTitleStyle()
        createdLabel.applyFootnoteStyle()
        paymentLabel.applyStatusStyle(for: order.status)
    }
}
