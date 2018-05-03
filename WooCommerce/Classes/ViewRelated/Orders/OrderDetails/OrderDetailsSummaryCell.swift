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

    var paymentBackgroundColor: UIColor? {
        get {
            return paymentLabel.backgroundColor
        }
        set {
            paymentLabel.backgroundColor = newValue
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
