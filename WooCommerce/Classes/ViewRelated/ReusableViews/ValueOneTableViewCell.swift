import UIKit

class ValueOneTableViewCell: UITableViewCell {

    override func awakeFromNib() {
        super.awakeFromNib()

        configureBackground()
        configureTextLabel()
        configureDetailTextLabel()
    }
}


extension ValueOneTableViewCell {
    fileprivate func configureBackground() {
        applyDefaultBackgroundStyle()
    }

    fileprivate func configureTextLabel() {
        textLabel?.applyBodyStyle()
    }

    fileprivate func configureDetailTextLabel() {
        detailTextLabel?.applySubheadlineStyle()
        detailTextLabel?.lineBreakMode = .byWordWrapping
        detailTextLabel?.numberOfLines = 0
    }
}
