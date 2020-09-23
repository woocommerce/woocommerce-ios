import UIKit

/// Displays an item to be refunded
///
final class RefundItemTableViewCell: UITableViewCell {

    /// Item image view: Product image
    ///
    @IBOutlet private var itemImageView: UIImageView!

    /// Item title: Product name
    ///
    @IBOutlet private var itemTitle: UILabel!

    /// Item caption: Product quanity and price
    ///
    @IBOutlet private var itemCaption: UILabel!

    /// Quantity button: Quantity to be refunded
    ///
    @IBOutlet private var itemQuantityButton: UIButton!

    override func awakeFromNib() {
        super.awakeFromNib()
    }
}

// MARK: Actions
private extension RefundItemTableViewCell {
    @IBAction func quantityButtonPressed(_ sender: Any) {
        print("Item quantity button pressed")
    }
}

#if canImport(SwiftUI) && DEBUG

// MARK: - Previews

import SwiftUI

private struct RefundItemTableViewCellRepresentable: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let nib = UINib(nibName: "RefundItemTableViewCell", bundle: nil)
        let views = nib.instantiate(withOwner: self, options: nil)
        return views.first as! UIView
    }

    func updateUIView(_ view: UIView, context: Context) {
        // no op
    }
}

@available(iOS 13.0, *)
struct RefundItemTableViewCell_Previews: PreviewProvider {

    private static func makeStack() -> some View {
        VStack {
            RefundItemTableViewCellRepresentable()
        }
    }

    static var previews: some View {
        Group {
            makeStack()
                .previewLayout(.fixed(width: 359, height: 76))
                .previewDisplayName("Light")

            makeStack()
                .previewLayout(.fixed(width: 359, height: 76))
                .environment(\.colorScheme, .dark)
                .previewDisplayName("Dark")

            makeStack()
                .previewLayout(.fixed(width: 359, height: 100))
                .environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge)
                .previewDisplayName("Large Font")
        }
    }
}

#endif
