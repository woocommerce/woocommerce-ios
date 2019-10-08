import UIKit

class ValueOneTableViewCell: UITableViewCell {

    override func awakeFromNib() {
        super.awakeFromNib()

        configureBackground()
        configureTextLabel()
        configureDetailTextLabel()
    }
}


private extension ValueOneTableViewCell {
    func configureBackground() {
        applyDefaultBackgroundStyle()
    }

    func configureTextLabel() {
        textLabel?.applyBodyStyle()
    }

    func configureDetailTextLabel() {
        detailTextLabel?.applySubheadlineStyle()
        detailTextLabel?.lineBreakMode = .byWordWrapping
        detailTextLabel?.numberOfLines = 0
    }
}
