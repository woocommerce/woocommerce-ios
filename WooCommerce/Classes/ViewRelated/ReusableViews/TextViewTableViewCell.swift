import UIKit
import Gridicons

class TextViewTableViewCell: UITableViewCell {

    @IBOutlet var noteIconButton: UIButton!

    @IBOutlet var noteTextView: UITextView!

    var iconImage: UIImage? {
        get {
            return noteIconButton.image(for: .normal)
        }
        set {
            noteIconButton.setImage(newValue, for: .normal)
            noteIconButton.tintColor = .listForeground
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

private extension TextViewTableViewCell {
    func configureBackground() {
        applyDefaultBackgroundStyle()
    }

    func configureTextView() {
        noteTextView.delegate = self
        noteTextView.backgroundColor = .listForeground
    }
}
