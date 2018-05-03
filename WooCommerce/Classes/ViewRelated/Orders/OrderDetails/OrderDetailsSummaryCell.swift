import UIKit

class OrderDetailsSummaryCell: UITableViewCell {
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var createdLabel: UILabel!
    @IBOutlet private weak var paymentLabel: PaddedLabel!

    static let reuseIdentifier = "OrderDetailsSummaryCell"

    var title: String? {
        get {
            return titleLabel.text
        }
        set {
            titleLabel.text = newValue
        }
    }

    var dateCreated: String? {
        get {
            return createdLabel.text
        }
        set {
            createdLabel.text = newValue
        }
    }

    var paymentStatus: String? {
        get {
            return paymentLabel.text
        }
        set {
            paymentLabel.text = newValue
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        refreshLabelStyles()
    }
}

private extension OrderDetailsSummaryCell {
    func refreshLabelStyles() {
        titleLabel.applyTitleStyle()
        createdLabel.applyFootnoteStyle()
        guard let paymentStatus = paymentStatus else {
            return
        }
        paymentLabel.applyStatusStyle(for: paymentStatus)
    }
}
