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


extension TitleBodyTableViewCell {
    fileprivate func configureBackground() {
        applyDefaultBackgroundStyle()
    }

    fileprivate func configureTitleLabel() {
        titleLabel?.applyHeadlineStyle()
    }

    fileprivate func configureBodyLabel() {
        bodyLabel?.applySecondaryBodyStyle()
    }
}
