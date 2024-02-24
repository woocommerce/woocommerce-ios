import UIKit

final class TitleBodyTableViewCell: UITableViewCell {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var bodyLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()

        configureBackground()
        configureTitleLabel()
        configureBodyLabel()
    }

    override func updateConfiguration(using state: UICellConfigurationState) {
        super.updateConfiguration(using: state)
        updateDefaultBackgroundConfiguration(using: state)
    }
}


private extension TitleBodyTableViewCell {
    func configureBackground() {
        configureDefaultBackgroundConfiguration()
    }

    func configureTitleLabel() {
        titleLabel?.applyHeadlineStyle()
    }

    func configureBodyLabel() {
        bodyLabel?.applySecondaryBodyStyle()
    }
}
