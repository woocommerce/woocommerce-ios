import UIKit

/// Displays an item to be refunded
///
final class RefundItemTableViewCell: UITableViewCell {

    /// Item image view: Product image
    ///
    @IBOutlet private var itemImageView: UIImageView!

    /// Placeholder image view: Needed to show a placeholder that has some insets from the `itemImageView`
    ///
    @IBOutlet private var placeholderImageView: UIImageView!

    /// Item title: Product name
    ///
    @IBOutlet private var itemTitle: UILabel!

    /// Item caption: Product quantity and price
    ///
    @IBOutlet private var itemCaption: UILabel!

    /// Quantity button: Quantity to be refunded
    ///
    @IBOutlet private var itemQuantityButton: UIButton!

    /// Needed to change it's axis with larger accessibility traits
    ///
    @IBOutlet private var itemsStackView: UIStackView!

    /// Needed to make sure the `itemImageView` grows at the same ratio as the dynamic fonts
    ///
    @IBOutlet private var itemImageViewHeightConstraint: NSLayoutConstraint!

    /// Closure invoked when the user taps the quantity button
    ///
    var onQuantityTapped: (() -> ())?

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
private extension RefundItemTableViewCell {
    func applyCellStyles() {
        applyCellBackgroundStyle()
        applyItemImageStyles()
        applyLabelsStyles()
        applyRefundQuantityButtonStyle()
    }

    func applyItemImageStyles() {
        itemImageView.layer.borderWidth = Constants.itemImageViewBorderWidth
        itemImageView.layer.borderColor = UIColor.border.cgColor
    }

    func applyCellBackgroundStyle() {
        applyDefaultBackgroundStyle()
    }

    func applyLabelsStyles() {
        itemTitle.applyBodyStyle()
        itemCaption.applyFootnoteStyle()
    }

    func applyRefundQuantityButtonStyle() {
        itemQuantityButton.applySecondaryButtonStyle()
        itemQuantityButton.titleLabel?.applyBodyStyle()
        itemQuantityButton.contentEdgeInsets = Constants.quantityButtonInsets

        itemQuantityButton.accessibilityLabel = Localization.quantity
        itemQuantityButton.accessibilityHint = Localization.quantityHint
    }
}

// MARK: Accessibility
private extension RefundItemTableViewCell {
    func applyAccessibilityChanges() {
        adjustItemsStackViewAxis()
        adjustItemImageViewHeight()
    }

    /// Changes the items stack view axis depending on the view `preferredContentSizeCategory`.
    ///
    func adjustItemsStackViewAxis() {
        itemsStackView.axis = traitCollection.preferredContentSizeCategory > .accessibilityMedium ? .vertical : .horizontal
    }

    /// Changes the items image view height acording to the current trait collection
    ///
    func adjustItemImageViewHeight() {
        itemImageViewHeightConstraint.constant = UIFontMetrics.default.scaledValue(for: Constants.itemImageViewHeight, compatibleWith: traitCollection)
    }
}

// MARK: ViewModel Rendering
extension RefundItemTableViewCell {

    /// Configure cell with the provided view model
    ///
    func configure(with viewModel: RefundItemViewModel, imageService: ImageService) {
        itemTitle.text = viewModel.productTitle
        itemCaption.text = viewModel.productQuantityAndPrice
        itemQuantityButton.setTitle(viewModel.quantityToRefund, for: .normal)

        guard let productImage = viewModel.productImage else {
            itemImageView.image = nil
            placeholderImageView.image = .productPlaceholderImage
            return
        }

        placeholderImageView.image = nil
        imageService.downloadAndCacheImageForImageView(itemImageView,
                                                       with: productImage,
                                                       placeholder: nil,
                                                       progressBlock: nil,
                                                       completion: nil)
    }
}

// MARK: Actions
private extension RefundItemTableViewCell {
    @IBAction func quantityButtonPressed(_ sender: Any) {
        onQuantityTapped?()
    }
}

// MARK: Constats
private extension RefundItemTableViewCell {
    enum Constants {
        static let itemImageViewHeight: CGFloat = 39.0
        static let itemImageViewBorderWidth: CGFloat = 0.5
        static let quantityButtonInsets = UIEdgeInsets(top: 8, left: 22, bottom: 8, right: 22)
    }

    enum Localization {
        static let quantity = NSLocalizedString("Quantity", comment: "The accessibility label for the quantity button when selecting an item to refund")
        static let quantityHint = NSLocalizedString("Tap to modify the item refund quantity",
                                                    comment: "The accessibility hint for the quantity button when selecting an item to refund")
    }
}

// MARK: - Previews
#if canImport(SwiftUI) && DEBUG

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
        cell.configure(with: viewModel, imageService: ServiceLocator.imageService)
        return cell
    }

    func updateUIView(_ view: UIView, context: Context) {
        // no op
    }
}

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
                .previewLayout(.fixed(width: 359, height: 96))
                .environment(\.sizeCategory, .accessibilityMedium)
                .previewDisplayName("Large Font")

            makeStack()
                .previewLayout(.fixed(width: 359, height: 420))
                .environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge)
                .previewDisplayName("Extra Large Font")
        }
    }
}

#endif
