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
        imageView.contentMode = .center
        imageView.clipsToBounds = true
    }
    
    func configureCellAppearance(){
        self.contentView.layer.cornerRadius = 2.0
        self.contentView.layer.borderWidth = 0.5
        self.contentView.layer.borderColor = StyleManager.tableViewCellSelectionStyle.cgColor
        self.contentView.layer.masksToBounds = true
    }
}
