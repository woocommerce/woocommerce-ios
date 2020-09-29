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

    override class func awakeFromNib() {
        super.awakeFromNib()
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
        return cell
    }

    func updateUIView(_ view: UIView, context: Context) {
        // no op
    }
}

@available(iOS 13.0, *)
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
                .previewLayout(.fixed(width: 359, height: 200))
                .environment(\.sizeCategory, .accessibilityMedium)
                .previewDisplayName("Large Font")
        }
    }
}

#endif
