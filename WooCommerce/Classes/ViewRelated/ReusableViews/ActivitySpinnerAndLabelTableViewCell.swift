import UIKit

final class ActivitySpinnerAndLabelTableViewCell: UITableViewCell {
    @IBOutlet private weak var label: UILabel!
    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!

    func configure(labelText: String) {
        label.text = labelText
    }

    /// Activity indicators in table view cells will stop animating
    /// when the cell is re-used, so we have to do this
    ///
    override func prepareForReuse() {
        super.prepareForReuse()
        activityIndicator.startAnimating()
    }
}
