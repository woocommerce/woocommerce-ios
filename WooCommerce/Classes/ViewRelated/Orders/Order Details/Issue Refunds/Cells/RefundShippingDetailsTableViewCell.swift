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
