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
    @IBOutlet weak var productLabelHolder: UIView!
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
        productStatusLabel.text = viewModel.productStatus.description
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
        productStatusLabel.textColor = UIColor.black
        productLabelHolder.backgroundColor = .gray(.shade5)
        productLabelHolder.layer.cornerRadius = CGFloat(4.0)
    }

    func configureProductStatusLabel(productStatus: ProductStatus) {
        if productStatus == ProductStatus.draft {
                let statusLabel = NSLocalizedString("Draft", comment: "Display label for the product's draft status")
                productLabelHolder.isHidden = false
                productStatusLabel.isHidden = false
                productStatusLabel.text? = statusLabel
            } else {
                productLabelHolder.isHidden = true
                productStatusLabel.isHidden = true
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
