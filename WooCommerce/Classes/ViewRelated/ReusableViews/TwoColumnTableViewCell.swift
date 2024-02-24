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

    override func updateConfiguration(using state: UICellConfigurationState) {
        super.updateConfiguration(using: state)
        updateDefaultBackgroundConfiguration(using: state)
    }
}


private extension TwoColumnTableViewCell {
    func configureBackground() {
        configureDefaultBackgroundConfiguration()
    }

    func configureLeftLabel() {
        leftLabel.applyBodyStyle()
    }

    func configureRightLabel() {
        rightLabel.applyBodyStyle()
    }
}
