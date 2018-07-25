import UIKit
import Gridicons

class WriteCustomerNoteTableViewCell: UITableViewCell {

    @IBOutlet var noteIconButton: UIButton! {
        didSet {
            noteIconButton.layer.cornerRadius = noteIconButton.frame.width / 2
            noteIconButton.tintColor = .white
            noteIconButton.setImage(Gridicon.iconOfType(.aside), for: .normal)
        }
    }

    @IBOutlet var noteTextView: UITextView!

    public var isCustomerNote: Bool! {
        didSet {
            noteIconButton.backgroundColor = isCustomerNote ? StyleManager.statusPrimaryBoldColor : StyleManager.wooGreyMid
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    func configure(isNoteToCustomer: Bool) {
        isCustomerNote = isNoteToCustomer
    }
}
