import Foundation
import UIKit


// MARK: - VerticalButton: Renders the titleLabel *below* the imageView!
//
class VerticalButton: UIButton {

    // MARK: - Overridden Methods

    override func awakeFromNib() {
        super.awakeFromNib()

        contentEdgeInsets = Settings.edgeInsets
        layer.cornerRadius = Settings.cornerRadius
        titleLabel?.font = UIFont.footnote
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        guard let imageView = imageView, let image = imageView.image, let titleLabel = titleLabel else {
            return
        }

        let imageSize = image.size
        let maxTitleSize = CGSize(width: frame.width, height: frame.height - imageSize.height)
        var titleSize = titleLabel.sizeThatFits(maxTitleSize)

        // Prevent Overflowing the container's area
        titleSize.width = min(frame.width, titleSize.width)

        // Layout: Image
        imageView.frame = CGRect(x: (frame.width - imageSize.width) * 0.5,
                                 y: (frame.height - imageSize.height - titleSize.height) * 0.5,
                                 width: imageSize.width,
                                 height: imageSize.height).integral

        // Layout: Title
        titleLabel.frame = CGRect(x: (frame.width - titleSize.width) * 0.5,
                                  y: imageView.frame.maxY + Settings.labelPaddingTop,
                                  width: titleSize.width,
                                  height: titleSize.height).integral
    }
}


// MARK: - Private
//
private extension VerticalButton {

    enum Settings {
        static let cornerRadius     = CGFloat(10)
        static let edgeInsets       = UIEdgeInsets(top: 5, left: 0, bottom: 5, right: 0)
        static let labelPaddingTop  = CGFloat(2)
    }
}
