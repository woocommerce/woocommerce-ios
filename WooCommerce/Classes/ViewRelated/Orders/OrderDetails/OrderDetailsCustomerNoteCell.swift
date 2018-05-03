import UIKit
import Gridicons

class OrderDetailsCustomerNoteCell: UITableViewCell {
    @IBOutlet private weak var noteLabel: UILabel!
    @IBOutlet private weak var iconImageView: UIImageView!

    static let reuseIdentifier = "OrderDetailsCustomerNoteCell"

    var quote: String? {
        get {
            return noteLabel.text
        }
        set {
            noteLabel.text = newValue ?? ""
            noteLabel.applyBodyStyle()
            iconImageView.image = Gridicon.iconOfType(.quote)
            iconImageView.tintColor = .black
        }
    }
}

extension OrderDetailsCustomerNoteCell {
    func configure(with viewModel: OrderDetailsViewModel) {
        quote = viewModel.customerNote
    }
}
