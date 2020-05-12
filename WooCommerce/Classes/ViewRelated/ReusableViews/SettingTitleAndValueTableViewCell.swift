import UIKit

final class SettingTitleAndValueTableViewCell: UITableViewCell {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var valueLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        configureBackground()
        configureLabels()
    }
}

// MARK: Updates
//
extension SettingTitleAndValueTableViewCell {
    func updateUI(title: String, value: String?) {
        titleLabel.text = title
        valueLabel.text = value
    }
}

// MARK: Configurations
//
private extension SettingTitleAndValueTableViewCell {
    func configureBackground() {
        applyDefaultBackgroundStyle()
    }

    func configureLabels() {
        titleLabel.applyBodyStyle()
        titleLabel.textColor = .text

        valueLabel.applyBodyStyle()
        valueLabel.textColor = .textSubtle
    }

    func applyNonSelectableLabelsStyle() {
        titleLabel.applyBodyStyle()
        titleLabel.textColor = .text

        valueLabel.applyBodyStyle()
        valueLabel.textColor = .textTertiary
    }
}
