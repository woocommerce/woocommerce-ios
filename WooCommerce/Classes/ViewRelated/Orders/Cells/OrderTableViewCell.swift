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

        paymentStatusLabel.text = viewModel.order.statusKey.description
        paymentStatusLabel.applyStyle(for: viewModel.order.statusKey)
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
        paymentStatusLabel.layer.borderColor = UIColor.clear.cgColor
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
