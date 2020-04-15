import UIKit

final class EnhancedTextView: UITextView {

    var placeholder: String? {
        didSet {
            placeholderLabel?.text = placeholder
            placeholderLabel?.sizeToFit()
        }
    }
    private var placeholderLabel: UILabel?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        delegate = self
        placeholderLabel = UILabel(frame: self.bounds)
        //placeholderLabel?.font = UIFont(name: "HelveticaNeue", size: 15.0)
        placeholderLabel?.numberOfLines = 0
        placeholderLabel?.textColor = .gray
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
