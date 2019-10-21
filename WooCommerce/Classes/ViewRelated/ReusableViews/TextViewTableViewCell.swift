import Gridicons
import UIKit

class TextViewTableViewCell: UITableViewCell {

    @IBOutlet var noteIconButton: UIButton!

    @IBOutlet var noteTextView: UITextView!

    var iconImage: UIImage? {
        get {
            return noteIconButton.image(for: .normal)
        }
        set {
            noteIconButton.setImage(newValue, for: .normal)
            noteIconButton.tintColor = .white
            noteIconButton.layer.cornerRadius = noteIconButton.frame.width / 2
        }
    }

    var iconTint: UIColor? {
        get {
            return noteIconButton.backgroundColor
        }
        set {
            noteIconButton.backgroundColor = newValue
        }
    }

    var onTextChange: ((String) -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()

        configureBackground()
        configureTextView()

        noteIconButton.accessibilityTraits = .image
    }
}


extension TextViewTableViewCell: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        onTextChange?(noteTextView.text)
    }
}

extension TextViewTableViewCell {
    fileprivate func configureBackground() {
        applyDefaultBackgroundStyle()
    }

    fileprivate func configureTextView() {
        noteTextView.delegate = self
        // Overriding the textview user interface style until Dark Mode
        // is fully supported
        if #available(iOS 13.0, *) {
            noteTextView.overrideUserInterfaceStyle = .light
        }
    }
}
