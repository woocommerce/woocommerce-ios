import UIKit

class AddProductImageCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var view: UIView!
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
private extension AddProductImageCollectionViewCell {
    func configureBackground() {
        applyDefaultBackgroundStyle()
    }

    func configureImageView() {
        imageView.image = UIImage.addImage
        imageView.contentMode = Settings.imageContentMode
        imageView.clipsToBounds = Settings.clipToBounds
    }

    func configureCellAppearance() {
        self.contentView.layer.cornerRadius = Constants.cornerRadius
        self.contentView.layer.borderWidth = Constants.borderWidth
        self.contentView.layer.borderColor = Colors.borderColor
        self.contentView.layer.masksToBounds = Settings.maskToBounds
    }
}

/// Constants
///
private extension AddProductImageCollectionViewCell {
    enum Constants {
        static let cornerRadius = CGFloat(2.0)
        static let borderWidth = CGFloat(0.5)
    }

    enum Colors {
        static let borderColor = StyleManager.tableViewCellSelectionStyle.cgColor
    }

    enum Settings {
        static let clipToBounds = true
        static let imageContentMode = ContentMode.center
        static let maskToBounds = true
    }
}
