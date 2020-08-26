import UIKit

/// A text view which support the placeholder label.
///
final class EnhancedTextView: UITextView {

    var onTextChange: ((String) -> Void)?
    var onTextDidBeginEditing: (() -> Void)?

    var placeholder: String? {
        didSet {
            placeholderLabel?.text = placeholder
            placeholderLabel?.sizeToFit()
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
        let frameRect = CGRect(x: Constants.margin, y: Constants.margin, width: bounds.width, height: bounds.height)
        placeholderLabel = UILabel(frame: frameRect)
        if let unwrappedLabel = placeholderLabel {
            addSubview(unwrappedLabel)
        }
        placeholderLabel?.numberOfLines = 0
        placeholderLabel?.applyBodyStyle()
        placeholderLabel?.textColor = .textSubtle
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
        static let margin = 0.0
    }
}
