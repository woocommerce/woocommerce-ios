import UIKit

class ExtendedAddProductImageCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var title: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        configureBackground()
        configureImageView()
        configureLabel()
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
        title.applyBodyStyle()
        title.textAlignment = .center
        title.text = NSLocalizedString("Add a product image", comment: "Cell text in Add / Edit product when there are no images.")
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
