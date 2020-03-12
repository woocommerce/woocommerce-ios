import UIKit

final class SettingTitleAndValueTableViewCell: UITableViewCell {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var valueLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()

        configureLabels()
        applyDefaultBackgroundStyle()
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
    func configureLabels() {
        titleLabel.applyBodyStyle()
        titleLabel.textColor = .text

        valueLabel.applyBodyStyle()
        valueLabel.textColor = .textSubtle
    }
}
