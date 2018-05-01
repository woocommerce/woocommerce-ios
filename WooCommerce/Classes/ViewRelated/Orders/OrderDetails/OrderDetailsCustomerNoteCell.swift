import UIKit
import Gridicons

class OrderDetailsCustomerNoteCell: UITableViewCell {
    @IBOutlet weak var noteLabel: UILabel!
    @IBOutlet weak var iconImageView: UIImageView!

    static let reuseIdentifier = "OrderDetailsCustomerNoteCell"

    func configureCell(note: String?) {
        if let note = note {
            noteLabel.text = note
        } else {
            noteLabel.text = ""
        }
        noteLabel.applyBodyStyle()
        iconImageView.image = Gridicon.iconOfType(.quote)
        iconImageView.tintColor = .black
    }
}
