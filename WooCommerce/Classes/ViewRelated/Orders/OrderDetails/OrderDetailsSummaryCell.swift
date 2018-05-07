import UIKit

class OrderDetailsSummaryCell: UITableViewCell {
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var createdLabel: UILabel!
    @IBOutlet private weak var paymentLabel: PaddedLabel!

    var paymentBackgroundColor: UIColor = .clear

    static let reuseIdentifier = "OrderDetailsSummaryCell"

    var title: String? {
        get {
            return titleLabel.text
        }
        set {
            titleLabel.text = newValue
            titleLabel.applyTitleStyle()
        }
    }

    var dateCreated: String? {
        get {
            return createdLabel.text
        }
        set {
            createdLabel.text = newValue
            createdLabel.applyFootnoteStyle()
        }
    }

    var paymentStatus: String? {
        get {
            return paymentLabel.text
        }
        set {
            paymentLabel.text = newValue
            paymentLabel.applyPaddedLabelDefaultStyles()
        }
    }

    var paymentBorderColor: CGColor? {
        get {
            return paymentLabel.layer.borderColor
        }
        set {
            paymentLabel.layer.borderColor = newValue
        }
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // label background colors get reset upon selection
        // to fix it, re-assign the background color
        paymentLabel.backgroundColor = paymentBackgroundColor
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        // label background colors get reset upon highlight
        // to fix it, re-assign the background color
        paymentLabel.backgroundColor = paymentBackgroundColor
    }
}

extension OrderDetailsSummaryCell {
    func configure(with viewModel: OrderDetailsViewModel) {
        title = viewModel.summaryTitle
        dateCreated = viewModel.dateCreated
        paymentStatus = viewModel.paymentStatus
        paymentBackgroundColor = viewModel.paymentBackgroundColor
        paymentBorderColor = viewModel.paymentBorderColor
    }
}
