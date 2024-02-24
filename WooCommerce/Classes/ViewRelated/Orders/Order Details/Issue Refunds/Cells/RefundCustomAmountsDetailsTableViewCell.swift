import UIKit

final class RefundCustomAmountsDetailsTableViewCell: UITableViewCell {
    /// Displays `Subtotal` title
    ///
    @IBOutlet private var subtotalTitleLabel: UILabel!

    /// Displays the subtotal value
    ///
    @IBOutlet private var subtotalPriceLabel: UILabel!

    /// Displays `Tax` title
    ///
    @IBOutlet private var taxTitleLabel: UILabel!

    /// Displays the tax value
    ///
    @IBOutlet private var taxPriceLabel: UILabel!

    /// Displays `Total` title
    ///
    @IBOutlet private var totalTitleLabel: UILabel!

    /// Displays the total value
    ///
    @IBOutlet private var totalPriceLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        applyCellStyles()
    }

    override func updateConfiguration(using state: UICellConfigurationState) {
        super.updateConfiguration(using: state)
        updateDefaultBackgroundConfiguration(using: state)
    }
}

// MARK: View Styles Configuration

private extension RefundCustomAmountsDetailsTableViewCell {
    func applyCellStyles() {
        configureDefaultBackgroundConfiguration()
        applyLabelsStyles()
    }

    func applyLabelsStyles() {
        subtotalTitleLabel.applyBodyStyle()
        subtotalPriceLabel.applyBodyStyle()
        taxTitleLabel.applyBodyStyle()
        taxPriceLabel.applyBodyStyle()
        totalTitleLabel.applyHeadlineStyle()
        totalPriceLabel.applyHeadlineStyle()

        taxTitleLabel.text = Localization.taxTitle
        subtotalTitleLabel.text = Localization.subtotalTitle
        totalTitleLabel.text = Localization.totalTitle
    }
}

// MARK: ViewModel Rendering

extension RefundCustomAmountsDetailsTableViewCell {

    /// Configure cell with the provided view model
    ///
    func configure(with viewModel: RefundCustomAmountsDetailsViewModel) {
        taxPriceLabel.text = viewModel.feesTaxes
        subtotalPriceLabel.text = viewModel.feesSubtotal
        totalPriceLabel.text = viewModel.feesTotal
    }
}

// MARK: Constants

private extension RefundCustomAmountsDetailsTableViewCell {
    enum Localization {
        static let taxTitle = NSLocalizedString(
            "Tax", comment: "Title on the refunds screen that lists the fees tax cost")
        static let subtotalTitle = NSLocalizedString(
            "Subtotal", comment: "Title on the refund screen that lists the fees subtotal cost")
        static let totalTitle = NSLocalizedString("refundCustomAmountsDetails.totalTitle",
                                                  value: "Custom Amounts Refund",
                                                  comment: "Title on the refund screen that lists the custom amounts total cost")
    }
}
