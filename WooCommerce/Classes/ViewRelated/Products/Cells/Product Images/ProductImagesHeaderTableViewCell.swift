import UIKit
import Yosemite

final class ProductImagesHeaderTableViewCell: UITableViewCell {

    @IBOutlet weak var collectionView: UICollectionView!

    /// View Model
    ///
    private var viewModel: ProductImagesViewModel?

    /// Collection View Datasource
    ///
    private var datasource: ProductImagesCollectionViewDatasource?

    /// Closure to be executed when a image cell is tapped
    ///
    var onImageSelected: ((ProductImage?, IndexPath?) -> Void)?

    /// Closure to be executed when add image cell is tapped
    ///
    var onAddImage: (() -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()

        configureBackground()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

    /// Configure cell
    ///
    func configure(with product: Product, config: ProductImagesCellConfig) {
        let viewModel = ProductImagesViewModel(product: product, config: config)
        self.viewModel = viewModel
        datasource = ProductImagesCollectionViewDatasource(viewModel: viewModel)

        configureCollectionView(config: config)

        viewModel.registerCollectionViewCells(collectionView)
    }

}

// MARK: - Collection View Delegate
//
extension ProductImagesHeaderTableViewCell: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        switch viewModel?.items[indexPath.item] {
        case .image:
            onImageSelected?(viewModel?.product.images[indexPath.item], indexPath)
        case .addImage:
            onAddImage?()
        case .extendedAddImage:
            onAddImage?()
        case .none:
            break
        }
    }
}

// MARK: - Collection View Flow Layout Delegate
//
extension ProductImagesHeaderTableViewCell: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {

//        if viewModel?.items[indexPath.item] == .image{
//            let cell = collectionView.cellForItem(at: indexPath) as? ProductImageCollectionViewCell
//            if let imageSize = cell?.imageView.image?.size{
//                return CGSize(width: (128 / imageSize.height) * imageSize.width, height: 128.0)
//            }
//        }

        switch viewModel?.items[indexPath.item] {
        case .extendedAddImage:
            return self.frame.size
        default:
            return ProductImagesViewModel.defaultCollectionViewCellSize
        }
    }
}

/// Cell configuration allowed
///
enum ProductImagesCellConfig {
        
        // only images
        case images
        
        // images + add image cell
        case addImages
        
        // only the extended add image cell
        case extendedAddImages
}

/// Private Methods
private extension ProductImagesHeaderTableViewCell {
    func configureBackground() {
        applyDefaultBackgroundStyle()
    }

    func configureCollectionView(config: ProductImagesCellConfig) {
        collectionView.delegate = self
        collectionView.dataSource = datasource
        collectionView.backgroundColor = StyleManager.wooWhite
        collectionView.showsHorizontalScrollIndicator = false
        switch config {
        case .extendedAddImages:
            collectionView.collectionViewLayout = ProductImagesFlowLayout(itemSize: self.frame.size)
        default:
            collectionView.collectionViewLayout = ProductImagesFlowLayout(itemSize: ProductImagesViewModel.defaultCollectionViewCellSize)
        }
    }
}
