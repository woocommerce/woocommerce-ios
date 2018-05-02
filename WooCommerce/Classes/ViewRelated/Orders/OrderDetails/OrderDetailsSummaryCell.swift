import UIKit

class OrderDetailsSummaryCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var createdLabel: UILabel!
    @IBOutlet weak var paymentLabel: PaddedLabel!

    var paymentStatusColor:UIColor = .clear

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
        paymentStatusColor = paymentLabel.backgroundColor ?? .clear
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // label background colors get reset upon selection
        // to fix it, re-assign the background color
        paymentLabel.backgroundColor = paymentStatusColor
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        // label background colors get reset upon highlight
        // to fix it, re-assign the background color
        paymentLabel.backgroundColor = paymentStatusColor
    }
}
