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
}

extension TextViewTableViewCell: UITextViewDelegate {
    func textViewDidChange() {
        onTextChange?(noteTextView.text)
    }
}
