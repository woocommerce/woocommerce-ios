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
        var onTextChange: ((_ text: String) -> Void)? = nil
        var onTextDidBeginEditing: (() -> Void)? = nil

        init(text: String?,
             productStatus: ProductStatus?,
             placeholder: String?,
             textViewMinimumHeight: CGFloat?,
             keyboardType: UIKeyboardType = .default,
             onTextChange: ((_ text: String?) -> Void)?) {
            self.text = text
            self.productStatus = productStatus ?? ProductStatus.draft
            self.placeholder = placeholder
            self.keyboardType = keyboardType
            self.onTextChange = onTextChange
        }
    }
    @IBOutlet weak var productStatusLabel: UILabel!
    @IBOutlet weak var productTextField: EnhancedTextView!

    // Constraints
    @IBOutlet private weak var textViewHeightConstraint: NSLayoutConstraint!
    override func awakeFromNib() {
        super.awakeFromNib()
        //configureBackground()
        //configureSeparator()
        configureLabelDetails()
    }

    func configure(with viewModel: ViewModel) {
        productTextField.text = viewModel.text
        productTextField.placeholder = viewModel.placeholder
        // TODO: Set constraint in IB.
        if let minimumHeight = viewModel.textViewMinimumHeight {
            textViewHeightConstraint.constant = minimumHeight
        }
        productStatusLabel.text = viewModel.productStatus.description // <--
        productTextField.isScrollEnabled = viewModel.isScrollEnabled
        productTextField.onTextChange = viewModel.onTextChange
        productTextField.onTextDidBeginEditing = viewModel.onTextDidBeginEditing
        productTextField.keyboardType = viewModel.keyboardType
        // TODO: Fix, this is breaking the text display if product status != Draft
        configureProductStatusLabel(productStatus: viewModel.productStatus)

    }

    override func becomeFirstResponder() -> Bool {
        productTextField.becomeFirstResponder()
    }
}
private extension LabeledTextViewTableViewCell {
    /// When the cell is tapped, the text field become the first responder
    ///
    @objc func cellTapped(sender: UIView) {
        productTextField.becomeFirstResponder()
    }

    func configureBackground() {
        backgroundColor = .systemColor(.secondarySystemGroupedBackground)
    }


    func configureLabelDetails() {
        productStatusLabel.font = UIFont.preferredFont(forTextStyle: .body)
        productStatusLabel.textAlignment = .center
    }

    func configureProductStatusLabel(productStatus: ProductStatus) {
            if productStatus == ProductStatus.draft {
                let statusLabel = NSLocalizedString(productStatus.description, comment: "Display label for the product's draft status")

                productStatusLabel.isHidden = false
                productStatusLabel.text? = statusLabel
            } else {
                productStatusLabel.isHidden = false
                productStatusLabel.text? = "|" // <-- If this is empty, the cell doesn't display the text either
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
