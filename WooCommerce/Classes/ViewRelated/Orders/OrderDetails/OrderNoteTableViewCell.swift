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

    @IBOutlet private var iconButton: UIButton!    
    @IBOutlet private var dateLabel: UILabel!
    @IBOutlet private var statusLabel: UILabel!
    @IBOutlet private var noteLabel: UILabel!

    var dateCreated: String? {
        get {
            return dateLabel.text
        }
        set {
            dateLabel.text = newValue
        }
    }

    var statusText: String? {
        get {
            return statusLabel.text
        }
        set {
            statusLabel.text = newValue
        }
    }

    var contents: String? {
        get {
            return noteLabel.text
        }
        set {
            noteLabel.text = newValue
        }
    }
}

extension OrderNoteTableViewCell {
    func configure(with viewModel: OrderNoteViewModel) {
        iconButton.setImage(viewModel.iconImage, for: .normal)
        iconButton.backgroundColor = viewModel.iconColor
        dateCreated = viewModel.formattedDateCreated
        statusText = viewModel.statusText
        contents = viewModel.contents
    }
}
