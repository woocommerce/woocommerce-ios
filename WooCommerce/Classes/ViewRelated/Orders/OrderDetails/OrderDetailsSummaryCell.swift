import UIKit

class OrderDetailsSummaryCell: UITableViewCell {
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var createdLabel: UILabel!
    @IBOutlet private weak var paymentStatusLabel: PaddedLabel!

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
            return paymentStatusLabel.text
        }
        set {
            paymentStatusLabel.text = newValue
            paymentStatusLabel.applyPaddedLabelDefaultStyles()
            paymentStatusLabel.backgroundColor = paymentBackgroundColor
        }
    }

    var paymentBorderColor: CGColor? {
        get {
            return paymentStatusLabel.layer.borderColor
        }
        set {
            paymentStatusLabel.layer.borderColor = newValue
        }
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        preserveLabelColors {
            super.setSelected(selected, animated: animated)
        }
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        preserveLabelColors {
            super.setHighlighted(highlighted, animated: animated)
        }
    }

    func preserveLabelColors(action: () -> Void) {
        action()
        paymentStatusLabel.backgroundColor = paymentBackgroundColor
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
