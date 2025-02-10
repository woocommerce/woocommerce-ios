import UIKit

final class FailedProductImageCollectionViewCell: UICollectionViewCell {

    @IBOutlet var imageView: UIImageView!
    @IBOutlet var effectView: UIVisualEffectView!
    @IBOutlet var errorImageView: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
        configureBackground()
        configureImageView()
        configureErrorImageView()
        configureCellAppearance()
    }
}

/// Private Methods
///
private extension FailedProductImageCollectionViewCell {
    func configureBackground() {
        applyGrayBackgroundStyle()
    }

    func configureImageView() {
        imageView.contentMode = Settings.imageContentMode
        imageView.clipsToBounds = Settings.clipToBounds
    }

    func configureBlurView() {
        let blurEffect = UIBlurEffect(style: .extraLight)
        effectView.effect = blurEffect
    }

    func configureErrorImageView() {
        errorImageView.tintColor = UIColor.error
    }

    func configureCellAppearance() {
        contentView.layer.cornerRadius = Constants.cornerRadius
        contentView.layer.borderWidth = Constants.borderWidth
        contentView.layer.borderColor = Colors.borderColor.cgColor
        contentView.layer.masksToBounds = Settings.maskToBounds
    }
}

/// Constants
///
private extension FailedProductImageCollectionViewCell {
    enum Constants {
        static let cornerRadius = CGFloat(2.0)
        static let borderWidth = CGFloat(0.5)
    }

    enum Colors {
        static let borderColor = UIColor.systemColor(.systemGray4)
    }

    enum Settings {
        static let clipToBounds = true
        static let imageContentMode = ContentMode.center
        static let maskToBounds = true
    }
}
