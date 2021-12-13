import UIKit

/// A text view which support the placeholder label.
///
final class EnhancedTextView: UITextView {

    var onTextChange: ((String) -> Void)?
    var onTextDidBeginEditing: (() -> Void)?

    var placeholder: String? {
        didSet {
            placeholderLabel?.text = placeholder
        }
    }
    private var placeholderLabel: UILabel?

    override var text: String! {
        didSet {
            if text.isEmpty {
                animatePlaceholder()
            }
            else {
                hidePlaceholder()
            }
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        delegate = self
        configurePlaceholderLabel()
    }

    private func animatePlaceholder() {
        UIView.animate(withDuration: Constants.animationDuration) { [weak self] in
            guard let self = self else {
                return
            }
            self.placeholderLabel?.alpha = self.text.isEmpty && !self.isFirstResponder ? 1 : 0
        }
    }

    private func hidePlaceholder() {
        UIView.animate(withDuration: Constants.animationDuration) { [weak self] in
            guard let self = self else {
                return
            }
            self.placeholderLabel?.alpha = 0
        }
    }

}


// MARK: Configurations
//
private extension EnhancedTextView {
    func configurePlaceholderLabel() {
        placeholderLabel = {
            let label = UILabel(frame: bounds)
            label.translatesAutoresizingMaskIntoConstraints = false
            addSubview(label)

            // Make placeholder left/right margins same as for the text container
            let leftPadding = textContainer.lineFragmentPadding + textContainerInset.left
            let rightPadding = textContainer.lineFragmentPadding + textContainerInset.right
            NSLayoutConstraint.activate([
                label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: leftPadding),
                label.widthAnchor.constraint(equalTo: widthAnchor, constant: -(leftPadding + rightPadding)),
                label.topAnchor.constraint(equalTo: topAnchor, constant: Constants.margin),
                label.heightAnchor.constraint(lessThanOrEqualTo: heightAnchor, constant: -Constants.margin)
            ])

            label.numberOfLines = 0
            label.applyBodyStyle()
            label.textColor = .textSubtle

            return label
        }()
    }
}

// MARK: UITextViewDelegate conformance
//
extension EnhancedTextView: UITextViewDelegate {

    func textViewDidBeginEditing(_ textView: UITextView) {
        hidePlaceholder()
        onTextDidBeginEditing?()
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        animatePlaceholder()
    }

    func textViewDidChange(_ textView: UITextView) {
        animatePlaceholder()
        onTextChange?(textView.text)
    }
}

// MARK: - Constants!
//
private extension EnhancedTextView {

    enum Constants {
        static let animationDuration = 0.2
        static let margin: CGFloat = 8.0
    }
}
