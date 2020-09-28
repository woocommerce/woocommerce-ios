import UIKit

/// TableViewCell that displays all information regarding shipping refunds
///
final class RefundShippingDetailsTableViewCell: UITableViewCell {

    /// Displays a truck image next to the carrier name
    ///
    @IBOutlet weak var shippingImageView: UIImageView!

    /// Displays the carrier name and shipping rate
    ///
    @IBOutlet weak var carrierLabel: UILabel!

    /// Display the shipping cost
    ///
    @IBOutlet weak var shippingPrice: UILabel!

    /// Displays `Subtotal` title
    ///
    @IBOutlet weak var subtotalTitleLabel: UILabel!

    /// Displays the subtotal value
    ///
    @IBOutlet weak var subtotalPriceLabel: UILabel!

    /// Displays `Tax` title
    ///
    @IBOutlet weak var taxTitleLabel: UILabel!

    /// Displays the tax value
    ///
    @IBOutlet weak var taxPriceLabel: UILabel!

    /// Displays `Shipping Refund` title
    ///
    @IBOutlet weak var shippingRefundTitleLabel: UILabel!

    /// Displays the total shipping cost to refund
    ///
    @IBOutlet weak var shippingRefundPriceLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        applyCellStyles()
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
        shippingPrice.applyFootnoteStyle()
        subtotalTitleLabel.applyBodyStyle()
        subtotalPriceLabel.applyBodyStyle()
        taxTitleLabel.applyBodyStyle()
        taxPriceLabel.applyBodyStyle()
        shippingRefundTitleLabel.applyBodyStyle()
        shippingRefundTitleLabel.font = .font(forStyle: .body, weight: .bold)
        shippingRefundPriceLabel.applyBodyStyle()
        shippingRefundPriceLabel.font = .font(forStyle: .body, weight: .bold)

        taxTitleLabel.text = Localization.taxTitle
        subtotalTitleLabel.text = Localization.subtotalTitle
        shippingRefundTitleLabel.text = Localization.totalTitle
    }

    func applyShippingImageViewStyles() {
        shippingImageView.contentMode = .center
        shippingImageView.image = .shippingImage
        shippingImageView.tintColor = .systemColor(.systemGray2)
        shippingImageView.layer.cornerRadius = Constants.iconCornerRadius
        shippingImageView.layer.borderWidth = Constants.iconBorderWitdh
        shippingImageView.layer.borderColor = UIColor.border.cgColor
    }
}

// MARK: ViewModel Rendering
extension RefundShippingDetailsTableViewCell {

    /// Configure cell with the provided view model
    ///
    func configure(with viewModel: RefundShippingDetailsViewModel) {
        carrierLabel.text = viewModel.carrierRate
        shippingPrice.text = viewModel.carrierCost
        taxPriceLabel.text = viewModel.shippingTax
        subtotalPriceLabel.text = viewModel.shippingSubtotal
        shippingRefundPriceLabel.text = viewModel.shippingTotal
    }
}

// MARK: Constants
private extension RefundShippingDetailsTableViewCell {
    enum Localization {
        static let taxTitle = NSLocalizedString("Tax", comment: "Title on the refunds screen that list the shipping tax cost")
        static let subtotalTitle = NSLocalizedString("Subtotal", comment: "Title on the refund screen that list the shipping subtotal cost")
        static let totalTitle = NSLocalizedString("Shipping Refund", comment: "Title on the refund screen that list the shipping total cost")
    }

    enum Constants {
        static let iconCornerRadius: CGFloat = 2.0
        static let iconBorderWitdh: CGFloat = 0.5
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

@available(iOS 13.0, *)
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

//            makeStack()
//                .previewLayout(.fixed(width: 359, height: 209))
//                .environment(\.layoutDirection, .rightToLeft)
//                .previewDisplayName("RTL")
//
//            makeStack()
//                .previewLayout(.fixed(width: 359, height: 300))
//                .environment(\.sizeCategory, .accessibilityMedium)
//                .previewDisplayName("Large Font")
//
//            makeStack()
//                .previewLayout(.fixed(width: 359, height: 620))
//                .environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge)
//                .previewDisplayName("Extra Large Font")
        }
    }
}

#endif
