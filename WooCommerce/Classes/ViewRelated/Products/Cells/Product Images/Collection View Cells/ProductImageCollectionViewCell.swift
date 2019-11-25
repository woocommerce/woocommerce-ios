import UIKit

class ProductImageCollectionViewCell: UICollectionViewCell {
    
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
        applyDefaultBackgroundStyle()
    }
    
    func configureImageView() {
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
    }
    
    func configureCellAppearance(){
        self.contentView.layer.cornerRadius = 2.0
        self.contentView.layer.borderWidth = 0.5
        self.contentView.layer.borderColor = StyleManager.tableViewCellSelectionStyle.cgColor
        self.contentView.layer.masksToBounds = true
    }
}
