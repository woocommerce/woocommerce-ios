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
    @IBOutlet weak var productLabelHolder: UIView! // Label holder
    @IBOutlet weak var productStatusLabel: UILabel! // Product label
    @IBOutlet var productTextField: EnhancedTextView! // Product name

    override func awakeFromNib() {
        super.awakeFromNib()
        configureLabelStyle()
        configureBackground()
    }

    func configure(with viewModel: ViewModel) {
        productTextField.text = viewModel.text
        productTextField.placeholder = viewModel.placeholder
        productStatusLabel.text = viewModel.productStatus.description
        productTextField.isScrollEnabled = viewModel.isScrollEnabled
        productTextField.onTextChange = viewModel.onNameChange
        productTextField.onTextDidBeginEditing = viewModel.onTextDidBeginEditing
        productTextField.keyboardType = viewModel.keyboardType
        configureProductStatusLabel(productStatus: viewModel.productStatus)
    }
}

private extension LabeledTextViewTableViewCell {

    func configureBackground() {
        backgroundColor = .systemColor(.secondarySystemGroupedBackground)
    }


    func configureLabelStyle() {
        productStatusLabel.font = UIFont.preferredFont(forTextStyle: .body)
        productStatusLabel.textAlignment = .center
        productStatusLabel.backgroundColor = UIColor.systemGray3
        productStatusLabel.layer.cornerRadius = CGFloat(4.0)
    }

    func configureProductStatusLabel(productStatus: ProductStatus) {
            if productStatus == ProductStatus.draft {
                let statusLabel = NSLocalizedString(productStatus.description, comment: "Display label for the product's draft status")

                productStatusLabel.isHidden = false
                productStatusLabel.text? = statusLabel
            } else {
                productLabelHolder.isHidden = true // Holder when status != draft
                productStatusLabel.text? = "" // Assure to empty the label string
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
