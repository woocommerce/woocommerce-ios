import UIKit

final class ExtendedAddProductImageCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var title: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        configureBackground()
        configureImageView()
    }

    func configurePlaceholderLabelForProductImages(isVariation: Bool) {
        title.applyEmptyStateTitleStyle()
        title.textAlignment = .center
        if isVariation {
            title.text = NSLocalizedString("Add a variation image", comment: "Cell text in Add / Edit variation when there are no images.")
        } else {
        title.text = NSLocalizedString("Add a product image", comment: "Cell text in Add / Edit product when there are no images.")
        }
    }

}

/// Private Methods
///
private extension ExtendedAddProductImageCollectionViewCell {
    func configureBackground() {
        applyGrayBackgroundStyle()
    }

    func configureImageView() {
        imageView.image = UIImage.addImage
        imageView.contentMode = Settings.imageContentMode
        imageView.clipsToBounds = Settings.clipToBounds
    }
}

/// Constants
///
private extension ExtendedAddProductImageCollectionViewCell {

    enum Settings {
        static let clipToBounds = true
        static let imageContentMode = ContentMode.center
        static let maskToBounds = true
    }
}
