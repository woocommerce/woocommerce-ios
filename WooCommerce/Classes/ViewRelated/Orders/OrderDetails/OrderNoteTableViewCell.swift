import UIKit

class OrderNoteTableViewCell: UITableViewCell {
    override func awakeFromNib() {
        super.awakeFromNib()

        dateLabel.applyBodyStyle()
        statusLabel.applyBodyStyle()
        noteLabel.applyBodyStyle()

        statusLabel.textColor = StyleManager.wooGreyMid
        iconButton.layer.cornerRadius = iconButton.frame.width / 2
        iconButton.tintColor = .white
    }

    @IBOutlet public var iconButton: UIButton!

    @IBOutlet private var dateLabel: UILabel!
    @IBOutlet private var statusLabel: UILabel!
    @IBOutlet private var noteLabel: UILabel!

    public var dateCreated: String? {
        get {
            return dateLabel.text
        }
        set {
            dateLabel.text = newValue
        }
    }

    public var statusText: String? {
        get {
            return statusLabel.text
        }
        set {
            statusLabel.text = newValue
        }
    }

    public var contents: String? {
        get {
            return noteLabel.text
        }
        set {
            noteLabel.text = newValue
        }
    }
}
