import UIKit

/// Used for variable vertical spacing between two table view cells.
/// The cell currently has default cell background color (`.listForeground`).
final class SpacerTableViewCell: UITableViewCell {
    /// The height of the spacer cell.
    var height: CGFloat = 0 {
        didSet {
            heightConstraint.constant = height
        }
    }

    @IBOutlet private weak var heightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var view: UIView!

    override func awakeFromNib() {
        super.awakeFromNib()

        applyDefaultBackgroundStyle()
        hideSeparator()
        view.backgroundColor = .clear
        selectionStyle = .none
    }
}
