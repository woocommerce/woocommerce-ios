import UIKit
import Gridicons

class OrderDetailsCustomerNoteCell: UITableViewCell {
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

    static let reuseIdentifier = "OrderDetailsCustomerNoteCell"

    var quote: String? {
        get {
            return noteLabel.text
        }
        set {
            noteLabel.text = newValue ?? ""
        }
    }
}

extension OrderDetailsCustomerNoteCell {
    func configure(with viewModel: OrderDetailsViewModel) {
        quote = viewModel.customerNote
    }
}
