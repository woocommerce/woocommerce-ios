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
}


private extension TitleBodyTableViewCell {
    func configureBackground() {
        applyDefaultBackgroundStyle()
    }

    func configureTitleLabel() {
        titleLabel?.applyHeadlineStyle()
    }

    func configureBodyLabel() {
        bodyLabel?.applySecondaryBodyStyle()
    }
}
