import UIKit


// MARK: - OrderTableViewCell
//
class OrderTableViewCell: UITableViewCell {

    /// Order's Title
    ///
    @IBOutlet private var titleLabel: UILabel!

    /// Order's Total
    ///
    @IBOutlet private var totalLabel: UILabel!

    /// Payment
    ///
    @IBOutlet private var paymentStatusLabel: PaddedLabel!


    /// Renders the specified Order ViewModel
    ///
    func configureCell(viewModel: OrderDetailsViewModel) {
        titleLabel.text = viewModel.summaryTitle
        totalLabel.text = viewModel.totalFriendlyString

        if let orderStatus = viewModel.orderStatus {
            paymentStatusLabel.applyStyle(for: orderStatus.status)
            paymentStatusLabel.text = orderStatus.name
        }
    }


    // MARK: - Overridden Methods

    override func awakeFromNib() {
        super.awakeFromNib()
        configureLabels()
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

    override func prepareForReuse() {
        super.prepareForReuse()
    }
}


// MARK: - Private
//
private extension OrderTableViewCell {

    /// Preserves the current Payment BG Color
    ///
    func preserveLabelColors(action: () -> Void) {
        let paymentColor = paymentStatusLabel.backgroundColor

        action()

        paymentStatusLabel.backgroundColor = paymentColor
    }

    /// Setup: Labels
    ///
    func configureLabels() {
        titleLabel.applyHeadlineStyle()
        totalLabel.applyBodyStyle()
        paymentStatusLabel.applyFootnoteStyle()
    }
}
