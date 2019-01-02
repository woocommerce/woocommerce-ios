import UIKit
import Gridicons

class CustomerNoteTableViewCell: UITableViewCell {
    @IBOutlet private weak var noteLabel: UILabel! {
        didSet {
            noteLabel.applyBodyStyle()
        }
    }

    @IBOutlet private weak var iconImageView: UIImageView! {
        didSet {
            iconImageView.image = Gridicon.iconOfType(.quote)
            iconImageView.tintColor = .black
        }
    }

    public var quote: String? {
        get {
            return noteLabel.text
        }
        set {
            noteLabel.text = newValue
        }
    }
}
