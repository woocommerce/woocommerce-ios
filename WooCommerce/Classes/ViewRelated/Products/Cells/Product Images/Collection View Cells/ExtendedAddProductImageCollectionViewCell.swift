import UIKit

final class ExtendedAddProductImageCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var title: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        configureBackground()
        configureImageView()
        configureLabel()
    }

    func configurePlaceholderLabelForProductImages(isVariation: Bool) {
        if isVariation {
            title.text = NSLocalizedString("Add a variation image", comment: "This text appears as a label in a collection view cell on the product variation editing screen when no images have been added yet, prompting the user to add their first variation image.")
        } else {
            title.text = NSLocalizedString("Add a product image", comment: "This text appears as a label in a collection view cell on the product editing screen, displayed when there are no product images to guide users to add their first image.")
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

    func configureLabel() {
        title.applyEmptyStateTitleStyle()
        title.textAlignment = .center
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
