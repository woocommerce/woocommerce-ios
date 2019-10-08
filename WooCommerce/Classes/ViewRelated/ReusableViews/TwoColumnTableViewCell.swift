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
        configureBackground()
        configureLeftLabel()
        configureRightLabel()
    }
}


private extension TwoColumnTableViewCell {
    func configureBackground() {
        applyDefaultBackgroundStyle()
    }

    func configureLeftLabel() {
        leftLabel.applyBodyStyle()
    }

    func configureRightLabel() {
        rightLabel.applyBodyStyle()
    }
}
