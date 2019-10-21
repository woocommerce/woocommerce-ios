import UIKit

/// Vertically aligns the image to the top of the cell instead of basic cell's center alignment.
///
class TopLeftImageTableViewCell: UITableViewCell {

    override func awakeFromNib() {
        super.awakeFromNib()

        configureBackground()
        configureTextLabel()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        imageView?.frame.size = CGSize(width: Constants.iconW, height: Constants.iconH)
        imageView?.frame.origin.y = Constants.iconY
    }
}


extension TopLeftImageTableViewCell {
    fileprivate func configureBackground() {
        applyDefaultBackgroundStyle()
    }

    fileprivate func configureTextLabel() {
        textLabel?.applyBodyStyle()
        textLabel?.numberOfLines = 0
    }
}

extension TopLeftImageTableViewCell {
    enum Constants {
        static let iconW = CGFloat(24)
        static let iconH = CGFloat(24)
        static let iconY = CGFloat(11)
    }
}
