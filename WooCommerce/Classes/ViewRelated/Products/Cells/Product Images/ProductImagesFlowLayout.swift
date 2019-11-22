import UIKit

/// Custom Collection View Flow Layout for Product Images
///
class ProductImagesFlowLayout: UICollectionViewFlowLayout {
    
    override func prepare() {
        super.prepare()
        
        self.scrollDirection = .horizontal
        self.minimumInteritemSpacing = 12.0
        self.minimumLineSpacing = 0.0
        self.estimatedItemSize = CGSize(width: 128.0, height: 128.0)
    }
}
