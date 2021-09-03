import UIKit

final class ActivitySpinnerAndLabelTableViewCell: UITableViewCell {
    @IBOutlet private weak var label: UILabel!

    func configure(labelText: String) {
        label.text = labelText
    }
}
