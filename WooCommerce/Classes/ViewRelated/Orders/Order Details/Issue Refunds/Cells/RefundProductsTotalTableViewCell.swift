import UIKit

/// `TableViewCell` that displays the products amount to be refunded
///
final class RefundProductsTotalTableViewCell: UITableViewCell {

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

    /// Displays `Products Refund` title
    ///
    @IBOutlet private var productsRefundTitleLabel: UILabel!

    /// Displays the total products costs to be refunded
    ///
    @IBOutlet private var productsRefundPriceLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        applyCellStyles()
    }
}

// MARK: View Styles Configuration
private extension RefundProductsTotalTableViewCell {
    func applyCellStyles() {
        applyDefaultBackgroundStyle()
        applyLabelsStyles()
    }

    func applyLabelsStyles() {
        subtotalTitleLabel.applyBodyStyle()
        subtotalPriceLabel.applyBodyStyle()
        taxTitleLabel.applyBodyStyle()
        taxPriceLabel.applyBodyStyle()
        productsRefundTitleLabel.applyHeadlineStyle()
        productsRefundPriceLabel.applyHeadlineStyle()

        taxTitleLabel.text = Localization.taxTitle
        subtotalTitleLabel.text = Localization.subtotalTitle
        productsRefundTitleLabel.text = Localization.totalTitle
    }
}

// MARK: ViewModel Rendering
extension RefundProductsTotalTableViewCell {

    /// Configure cell with the provided view model
    ///
    func configure(with viewModel: RefundProductsTotalViewModel) {
        taxPriceLabel.text = viewModel.productsTax
        subtotalPriceLabel.text = viewModel.productsSubtotal
        productsRefundPriceLabel.text = viewModel.productsTotal
    }
}

// MARK: Constants
private extension RefundProductsTotalTableViewCell {
    enum Localization {
        static let taxTitle = NSLocalizedString("Tax", comment: "Title on the refunds screen that lists the products refund tax cost")
        static let subtotalTitle = NSLocalizedString("Subtotal", comment: "Title on the refund screen that lists the products refund subtotal cost")
        static let totalTitle = NSLocalizedString("Products Refund", comment: "Title on the refund screen that lists the products refund total cost")
    }
}

// MARK: - Previews
#if canImport(SwiftUI) && DEBUG

import SwiftUI

private struct RefundProductsTotalTableViewCellRepresentable: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let nib = UINib(nibName: "RefundProductsTotalTableViewCell", bundle: nil)
        guard let cell = nib.instantiate(withOwner: self, options: nil).first as? RefundProductsTotalTableViewCell else {
            fatalError("Could not create RefundProductsTotalTableViewCell")
        }

        let viewModel = RefundProductsTotalViewModel(productsTax: "$2.50", productsSubtotal: "$12.30", productsTotal: "$14.80")
        cell.configure(with: viewModel)
        return cell
    }

    func updateUIView(_ view: UIView, context: Context) {
        // no op
    }
}

struct RefundProductsTotalTableViewCell_Previews: PreviewProvider {

    private static func makeStack() -> some View {
        VStack {
            RefundProductsTotalTableViewCellRepresentable()
        }
    }

    static var previews: some View {
        Group {
            makeStack()
                .previewLayout(.fixed(width: 359, height: 128))
                .previewDisplayName("Light")

            makeStack()
                .previewLayout(.fixed(width: 359, height: 128))
                .environment(\.colorScheme, .dark)
                .previewDisplayName("Dark")

            makeStack()
                .previewLayout(.fixed(width: 359, height: 150))
                .environment(\.sizeCategory, .accessibilityMedium)
                .previewDisplayName("Large Font")
        }
    }
}

#endif
