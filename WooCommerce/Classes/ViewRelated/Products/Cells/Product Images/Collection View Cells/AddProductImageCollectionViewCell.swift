import UIKit

class AddProductImageCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var view: UIView!
    @IBOutlet weak var imageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        configureBackground()
        configureImageView()
    }

}

/// Private Methods
private extension AddProductImageCollectionViewCell {
    func configureBackground() {
        applyDefaultBackgroundStyle()
    }
    
    func configureImageView() {
        imageView.image = UIImage.addImage
        imageView.contentMode = .center
        
    }
}
