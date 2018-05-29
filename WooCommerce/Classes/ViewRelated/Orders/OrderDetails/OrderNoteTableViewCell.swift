import UIKit

class OrderNoteTableViewCell: UITableViewCell {

    @IBOutlet private var iconButton: UIButton! {
        didSet {
            iconButton.layer.cornerRadius = iconButton.frame.width / 2
            iconButton.tintColor = .white
        }
    }
    @IBOutlet private var dateLabel: UILabel! {
        didSet {
            dateLabel.applyBodyStyle()
        }
    }
    @IBOutlet private var statusLabel: UILabel! {
        didSet {
            statusLabel.applyBodyStyle()
            statusLabel.textColor = StyleManager.wooGreyMid
        }
    }
    @IBOutlet private var noteLabel: UILabel! {
        didSet {
            noteLabel.applyBodyStyle()
        }
    }

    static let reuseIdentifier = "OrderNoteTableViewCell"

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
        dateCreated = viewModel.dateCreated
        statusText = viewModel.statusText
        contents = viewModel.contents
    }
}
