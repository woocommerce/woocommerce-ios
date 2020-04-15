import UIKit

/// A text view which support the placeholder label.
///
final class EnhancedTextView: UITextView {

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
        placeholderLabel = UILabel(frame: self.bounds)
        configureLabels()
        if let unwrappedLabel = placeholderLabel {
            addSubview(unwrappedLabel)
        }
    }

    private func animatePlaceholder(){
        UIView.animate(withDuration: 0.2) { [weak self] in
            guard let self = self else {
                return
            }
            self.placeholderLabel?.alpha = self.text.isEmpty && !self.isFirstResponder ? 1 : 0
        }
    }
    
    private func hidePlaceholder(){
        UIView.animate(withDuration: 0.2) { [weak self] in
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
    func configureLabels() {
        placeholderLabel?.numberOfLines = 0
        placeholderLabel?.applyBodyStyle()
        placeholderLabel?.textColor = .textSubtle
    }
}

// MARK: UITextViewDelegate conformance
//
extension EnhancedTextView: UITextViewDelegate{
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        self.hidePlaceholder()
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        self.animatePlaceholder()
    }
    
    func textViewDidChange(_ textView: UITextView) {
        self.animatePlaceholder()
    }
    
}
