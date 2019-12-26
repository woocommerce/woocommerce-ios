import UIKit

/// Custom Collection View Flow Layout for Product Images
///
final class ProductImagesFlowLayout: UICollectionViewFlowLayout {

    private let defaultItemSize: CGSize

    private let defaultInset: CGFloat = 16.0

    private var config: ProductImagesCellConfig

    init(itemSize: CGSize, config: ProductImagesCellConfig) {
        defaultItemSize = itemSize
        self.config = config
        super.init()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepare() {
        super.prepare()

        scrollDirection = .horizontal

        switch config {
        case .extendedAddImages:
            minimumInteritemSpacing = 0.0
            minimumLineSpacing = 0.00
            sectionInset = UIEdgeInsets(top: 0.0, left: 0.0, bottom: 0.0, right: 0.0)
        default:
            minimumInteritemSpacing = defaultInset
            minimumLineSpacing = defaultInset
            sectionInset = UIEdgeInsets(top: 0.0, left: defaultInset, bottom: 0.0, right: defaultInset)
        }

        itemSize = defaultItemSize
    }
}
