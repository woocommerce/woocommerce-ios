import UIKit

final class InProgressProductImageCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet private weak var blurView: UIVisualEffectView!
    @IBOutlet private weak var spinnerView: CircleSpinnerView!

    override func awakeFromNib() {
        super.awakeFromNib()
        configureBackground()
        configureImageView()
        configureBlurView()
        configureSpinner()
        configureCellAppearance()

        spinnerView.animate()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        spinnerView.animate()
    }
}

/// Private Methods
///
private extension InProgressProductImageCollectionViewCell {
    func configureBackground() {
        applyGrayBackgroundStyle()
    }

    func configureImageView() {
        imageView.contentMode = Settings.imageContentMode
        imageView.clipsToBounds = Settings.clipToBounds
    }

    func configureBlurView() {
        let blurEffect = UIBlurEffect(style: .extraLight)
        blurView.effect = blurEffect
    }

    func configureSpinner() {
        spinnerView.color = .brand
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
private extension InProgressProductImageCollectionViewCell {
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
