import UIKit

/// TableViewCell that displays all information regarding shipping refunds
///
final class RefundShippingDetailsTableViewCell: UITableViewCell {

    /// Displays a truck image next to the carrier name
    ///
    @IBOutlet private var shippingImageView: UIImageView!

    /// Displays the carrier name and shipping rate
    ///
    @IBOutlet private var carrierLabel: UILabel!

    /// Display the shipping cost
    ///
    @IBOutlet private var shippingPriceLabel: UILabel!

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

    /// Displays `Shipping Refund` title
    ///
    @IBOutlet private var shippingRefundTitleLabel: UILabel!

    /// Displays the total shipping cost to refund
    ///
    @IBOutlet private var shippingRefundPriceLabel: UILabel!

    /// Displays a border around the `shippingImageView`
    ///
    @IBOutlet private var shippingBorderView: UIView!

    /// Needed to make sure the `shippingImageView` grows at the same ratio as the dynamic fonts
    ///
    @IBOutlet private var shippingBorderViewHeightConstraint: NSLayoutConstraint!

    override func awakeFromNib() {
        super.awakeFromNib()
        applyCellStyles()
        applyAccessibilityChanges()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        applyAccessibilityChanges()
    }
}

// MARK: View Styles Configuration
private extension RefundShippingDetailsTableViewCell {
    func applyCellStyles() {
        applyDefaultBackgroundStyle()
        applyLabelsStyles()
        applyShippingImageViewStyles()
    }

    func applyLabelsStyles() {
        carrierLabel.applyBodyStyle()
        shippingPriceLabel.applyFootnoteStyle()
        subtotalTitleLabel.applyBodyStyle()
        subtotalPriceLabel.applyBodyStyle()
        taxTitleLabel.applyBodyStyle()
        taxPriceLabel.applyBodyStyle()
        shippingRefundTitleLabel.applyHeadlineStyle()
        shippingRefundPriceLabel.applyHeadlineStyle()

        taxTitleLabel.text = Localization.taxTitle
        subtotalTitleLabel.text = Localization.subtotalTitle
        shippingRefundTitleLabel.text = Localization.totalTitle
    }

    func applyShippingImageViewStyles() {
        shippingImageView.image = .shippingImage
        shippingImageView.tintColor = .systemColor(.systemGray2)
        shippingBorderView.layer.cornerRadius = Constants.shippingBorderCornerRadius
        shippingBorderView.layer.borderWidth = Constants.shippingBorderWidth
        shippingBorderView.layer.borderColor = UIColor.border.cgColor
    }
}

// MARK: ViewModel Rendering
extension RefundShippingDetailsTableViewCell {

    /// Configure cell with the provided view model
    ///
    func configure(with viewModel: RefundShippingDetailsViewModel) {
        carrierLabel.text = viewModel.carrierRate
        shippingPriceLabel.text = viewModel.carrierCost
        taxPriceLabel.text = viewModel.shippingTax
        subtotalPriceLabel.text = viewModel.shippingSubtotal
        shippingRefundPriceLabel.text = viewModel.shippingTotal
    }
}

// MARK: Accessibility
private extension RefundShippingDetailsTableViewCell {
    func applyAccessibilityChanges() {
        adjustShippingImageViewHeight()
    }

    /// Changes the shipping image view height acording to the current trait collection
    ///
    func adjustShippingImageViewHeight() {
        shippingBorderViewHeightConstraint.constant = UIFontMetrics.default.scaledValue(for: Constants.shippingBorderViewHeight,
                                                                                        compatibleWith: traitCollection)
    }
}

// MARK: Constants
private extension RefundShippingDetailsTableViewCell {
    enum Localization {
        static let taxTitle = NSLocalizedString("Tax", comment: "Title on the refunds screen that lists the shipping tax cost")
        static let subtotalTitle = NSLocalizedString("Subtotal", comment: "Title on the refund screen that lists the shipping subtotal cost")
        static let totalTitle = NSLocalizedString("Shipping Refund", comment: "Title on the refund screen that lists the shipping total cost")
    }

    enum Constants {
        static let shippingBorderCornerRadius: CGFloat = 2.0
        static let shippingBorderWidth: CGFloat = 0.5
        static let shippingBorderViewHeight: CGFloat = 40.0
    }
}

// MARK: - Previews
#if canImport(SwiftUI) && DEBUG

import SwiftUI

private struct RefundShippingDetailsTableViewCellRepresentable: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let nib = UINib(nibName: "RefundShippingDetailsTableViewCell", bundle: nil)
        guard let cell = nib.instantiate(withOwner: self, options: nil).first as? RefundShippingDetailsTableViewCell else {
            fatalError("Could not create RefundShippingDetailsTableViewCell")
        }

        let viewModel = RefundShippingDetailsViewModel(carrierRate: "USPS Flat Rate Shipping",
                                                       carrierCost: "$7.50",
                                                       shippingTax: "$3.00",
                                                       shippingSubtotal: "$7.50",
                                                       shippingTotal: "$10.50")
        cell.configure(with: viewModel)
        return cell
    }

    func updateUIView(_ view: UIView, context: Context) {
        // no op
    }
}

struct RefundShippingDetailsTableViewCell_Previews: PreviewProvider {

    private static func makeStack() -> some View {
        VStack {
            RefundShippingDetailsTableViewCellRepresentable()
        }
    }

    static var previews: some View {
        Group {
            makeStack()
                .previewLayout(.fixed(width: 359, height: 209))
                .previewDisplayName("Light")

            makeStack()
                .previewLayout(.fixed(width: 359, height: 209))
                .environment(\.colorScheme, .dark)
                .previewDisplayName("Dark")

            makeStack()
                .previewLayout(.fixed(width: 359, height: 300))
                .environment(\.sizeCategory, .accessibilityMedium)
                .previewDisplayName("Large Font")

            makeStack()
                .previewLayout(.fixed(width: 359, height: 600))
                .environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge)
                .previewDisplayName("Extra Large Font")
        }
    }
}

#endif
