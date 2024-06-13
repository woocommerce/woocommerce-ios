import UIKit
import Yosemite
/// A table view cell that contains a label and a text view.
///
final class LabeledTextViewTableViewCell: UITableViewCell {
    struct ViewModel {
        var text: String? = nil
        var productStatus: ProductStatus
        var placeholder: String? = nil
        var textViewMinimumHeight: CGFloat? = nil
        var isScrollEnabled: Bool = true
        var keyboardType: UIKeyboardType = .default
        var onNameChange: ((_ text: String) -> Void)? = nil
        var onTextDidBeginEditing: (() -> Void)? = nil
        var style: Style = .headline

    }

    @IBOutlet weak var productStatusBadgeHolder: UIView! // container with extra top margin for badge alignment
    @IBOutlet weak var productStatusBadgeBg: UIView!
    @IBOutlet weak var productStatusLabel: UILabel!
    @IBOutlet var productTextField: EnhancedTextView!

    override func awakeFromNib() {
        super.awakeFromNib()
        configureLabelStyle()
        configureBackground()
    }

    func configure(with viewModel: ViewModel) {
        productTextField.text = viewModel.text
        productTextField.placeholder = viewModel.placeholder
        productTextField.isScrollEnabled = viewModel.isScrollEnabled
        productTextField.onTextChange = viewModel.onNameChange
        productTextField.onTextDidBeginEditing = viewModel.onTextDidBeginEditing
        productTextField.keyboardType = viewModel.keyboardType
        configureProductStatusLabel(productStatus: viewModel.productStatus)
        applyStyle(style: viewModel.style)
    }
}

private extension LabeledTextViewTableViewCell {

    func configureBackground() {
        backgroundColor = .systemColor(.secondarySystemGroupedBackground)
        productTextField.backgroundColor = .systemColor(.secondarySystemGroupedBackground)
    }

    func configureLabelStyle() {
        productStatusLabel.font = UIFont.preferredFont(forTextStyle: .caption1)
        productStatusLabel.textAlignment = .center
        productStatusLabel.textColor = BadgeStyle.Colors.textColor
        productStatusBadgeBg.backgroundColor = BadgeStyle.Colors.defaultBg
        productStatusBadgeBg.layer.cornerRadius = BadgeStyle.cornerRadius
    }

    func configureProductStatusLabel(productStatus: ProductStatus) {

        switch productStatus {
        case .privateStatus:
            productStatusLabel.text = NSLocalizedString("productDetail.privateStatusLabel",
                                                        value: "Private published",
                                                        comment: "Display label in product for the product's private status"
            )
        default:
            productStatusLabel.text = productStatus.description
        }

        switch productStatus {
        case .pending:
            productStatusBadgeBg.backgroundColor = BadgeStyle.Colors.pendingBg
        default:
            productStatusBadgeBg.backgroundColor = BadgeStyle.Colors.defaultBg
        }

        productStatusBadgeHolder.isHidden = productStatus == .published
    }

    enum BadgeStyle {
        static let cornerRadius: CGFloat = 4

        enum Colors {
            static let textColor: UIColor = .black
            static let defaultBg: UIColor = .gray(.shade5)
            static let pendingBg: UIColor = .withColorStudio(.orange, shade: .shade10)
        }
    }
}

// Styles
extension LabeledTextViewTableViewCell {

    enum Style {
        case body
        case headline
    }

    func applyStyle(style: Style) {
        switch style {
        case .body:
            productTextField.adjustsFontForContentSizeCategory = true
            productTextField.font = .body
            productTextField.textColor = .text
        case .headline:
            productTextField.adjustsFontForContentSizeCategory = true
            productTextField.font = .headline
            productTextField.textColor = .text
        }
    }
}
