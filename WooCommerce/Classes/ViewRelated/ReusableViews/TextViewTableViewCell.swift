import UIKit
import Gridicons

class TextViewTableViewCell: UITableViewCell {

    @IBOutlet weak var noteIconView: UIView!
    @IBOutlet var noteIconButton: UIButton!

    @IBOutlet var noteTextView: EnhancedTextView!

    var iconImage: UIImage? {
        get {
            return noteIconButton.image(for: .normal)
        }
        set {
            noteIconButton.setImage(newValue, for: .normal)
            noteIconButton.tintColor = .listForeground
            noteIconButton.layer.cornerRadius = noteIconButton.frame.width / 2
            noteIconView.isHidden = newValue == nil
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

    override func awakeFromNib() {
        super.awakeFromNib()

        configureBackground()
        configureTextView()

        noteIconButton.accessibilityTraits = .image
    }
}

private extension TextViewTableViewCell {
    func configureBackground() {
        applyDefaultBackgroundStyle()
    }

    func configureTextView() {
        noteTextView.backgroundColor = .listForeground
    }
}
