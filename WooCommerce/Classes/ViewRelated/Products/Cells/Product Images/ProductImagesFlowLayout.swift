import UIKit

/// Custom Collection View Flow Layout for Product Images
///
class ProductImagesFlowLayout: UICollectionViewFlowLayout {

    private var defaultItemSize: CGSize
    
    private let defaultInset: CGFloat = 16.0
    
    private var config: ProductImagesCellConfig
    
    init(itemSize: CGSize, config: ProductImagesCellConfig) {
        self.defaultItemSize = itemSize
        self.config = config
        super.init()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepare() {
        super.prepare()

        self.scrollDirection = .horizontal
        
        switch config {
        case .extendedAddImages:
            self.minimumInteritemSpacing = 0.0
            self.minimumLineSpacing = 0.00
            self.sectionInset = UIEdgeInsets(top: 0.0, left: 0.0, bottom: 0.0, right: 0.0)
        default:
            self.minimumInteritemSpacing = defaultInset
            self.minimumLineSpacing = defaultInset
            self.sectionInset = UIEdgeInsets(top: 0.0, left: defaultInset, bottom: 0.0, right: defaultInset)
        }

        self.itemSize = defaultItemSize
    }
}
