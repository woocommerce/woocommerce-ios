import UIKit

class ProductImageCollectionViewCell: UICollectionViewCell {
    
    override func awakeFromNib() {
        super.awakeFromNib()
        configureBackground()
        configureCellAppearance()
    }

}


/// Private Methods
///
private extension ProductImageCollectionViewCell {
    func configureBackground() {
        applyDefaultBackgroundStyle()
    }
    
    func configureCellAppearance(){
        self.contentView.layer.cornerRadius = 2.0
        self.contentView.layer.borderWidth = 0.5
        self.contentView.layer.borderColor = StyleManager.tableViewCellSelectionStyle.cgColor
        self.contentView.layer.masksToBounds = true
    }
}
