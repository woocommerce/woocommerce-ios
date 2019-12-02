import UIKit

final class ProductImageCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var imageView: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
        configureBackground()
        configureImageView()
        configureCellAppearance()
    }
}

/// Private Methods
///
private extension ProductImageCollectionViewCell {
    func configureBackground() {
        applyGrayBackgroundStyle()
    }

    func configureImageView() {
        imageView.contentMode = Settings.imageContentMode
        imageView.clipsToBounds = Settings.clipToBounds
    }

    func configureCellAppearance() {
        contentView.layer.cornerRadius = Constants.cornerRadius
        contentView.layer.borderWidth = Constants.borderWidth
        contentView.layer.borderColor = Colors.borderColor
        contentView.layer.masksToBounds = Settings.maskToBounds
    }
}

/// Constants
///
private extension ProductImageCollectionViewCell {
    enum Constants {
        static let cornerRadius = CGFloat(2.0)
        static let borderWidth = CGFloat(0.5)
    }

    enum Colors {
        static let borderColor = UIColor.listBackground.cgColor
    }

    enum Settings {
        static let clipToBounds = true
        static let imageContentMode = ContentMode.scaleAspectFit
        static let maskToBounds = true
    }
}
