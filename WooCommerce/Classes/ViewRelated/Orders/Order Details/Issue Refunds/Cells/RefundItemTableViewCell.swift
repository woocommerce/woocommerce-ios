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

// MARK: ViewModel Rendering
extension RefundItemTableViewCell {

    /// Configure cell with the provided view model
    ///
    func configure(with viewModel: RefundItemViewModel) {
        itemImageView.image = .productPlaceholderImage
        itemTitle.text = viewModel.productTitle
        itemCaption.text = viewModel.productQuantityAndPrice
        itemQuantityButton.setTitle(viewModel.quantityToRefund, for: .normal)
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
        guard let cell = nib.instantiate(withOwner: self, options: nil).first as? RefundItemTableViewCell else {
            fatalError("Could not create RefundItemTableViewCell")
        }

        let viewModel = RefundItemViewModel(productImage: nil,
                                            productTitle: "Hoddie - Big",
                                            productQuantityAndPrice: "2 x $29.99 each",
                                            quantityToRefund: "1")
        cell.configure(with: viewModel)
        return cell
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
