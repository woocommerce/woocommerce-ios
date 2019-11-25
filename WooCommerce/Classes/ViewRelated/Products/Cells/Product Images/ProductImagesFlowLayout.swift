import UIKit

/// Custom Collection View Flow Layout for Product Images
///
class ProductImagesFlowLayout: UICollectionViewFlowLayout {
    
    private var defaultItemSize: CGSize
    
    init(itemSize: CGSize) {
        defaultItemSize = itemSize
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepare() {
        super.prepare()
        
        self.scrollDirection = .horizontal
        self.minimumInteritemSpacing = 16.0
        self.minimumLineSpacing = 16.0
        self.itemSize = defaultItemSize
        self.sectionInset = UIEdgeInsets(top: 0.0, left: 16.0, bottom: 0.0, right: 16.0)
    }
}
