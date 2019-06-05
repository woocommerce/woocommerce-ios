import UIKit

/// A two column table view cell with Body styling.
///
final class TwoColumnTableViewCell: UITableViewCell {

    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var leftLabel: UILabel!
    @IBOutlet weak var rightLabel: PaddedLabel!

    override func awakeFromNib() {
        super.awakeFromNib()

        stackView.isLayoutMarginsRelativeArrangement = true
        leftLabel.applyBodyStyle()
        rightLabel.applyBodyStyle()
    }
}
