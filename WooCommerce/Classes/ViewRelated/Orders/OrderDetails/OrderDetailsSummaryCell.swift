import UIKit

class OrderDetailsSummaryCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var createdLabel: UILabel!
    @IBOutlet weak var paymentLabel: PaddedLabel!

    static let reuseIdentifier = "OrderDetailsSummaryCell"

    func configureCell(order: Order) {
        let titleString = "#\(order.number) \(order.shippingAddress.firstName) \(order.shippingAddress.lastName)"
        let paymentStatusText = order.status.description
        let fuzzyDate = String.localizedStringWithFormat(NSLocalizedString("Created %@", comment: "Order created date"), order.dateCreatedString) // FIXME: needs fuzzy date

        titleLabel.text = titleString
        createdLabel.text = fuzzyDate
        paymentLabel.text = paymentStatusText

        titleLabel.applyTitleStyle()
        createdLabel.applyFootnoteStyle()
        paymentLabel.applyStatusStyle(for: order.status)
    }
}
