import UIKit

/// Custom Collection View Flow Layout for Product Images
///
class ProductImagesFlowLayout: UICollectionViewFlowLayout {
    
    override func prepare() {
        super.prepare()
        
        self.scrollDirection = .horizontal
        self.minimumInteritemSpacing = 0.0
        self.minimumLineSpacing = 16.0
        self.estimatedItemSize = CGSize(width: 128.0, height: 128.0)
        self.sectionInset = UIEdgeInsets(top: 0.0, left: 16.0, bottom: 0.0, right: 0.0)
    }
}
