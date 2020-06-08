import UIKit
import Yosemite

final class ProductImagesHeaderTableViewCell: UITableViewCell {

    @IBOutlet weak var collectionView: UICollectionView!

    /// View Model
    ///
    private var viewModel: ProductImagesHeaderViewModel?

    /// Collection View Datasource
    ///
    private var dataSource: ProductImagesCollectionViewDataSource?

    /// Closure to be executed when a image cell is tapped
    ///
    var onImageSelected: ((ProductImage?, IndexPath?) -> Void)?

    /// Closure to be executed when add image cell is tapped
    ///
    var onAddImage: (() -> Void)?

    /// Keeps track of the cell config to update collection view layout on change.
    ///
    private var config: ProductImagesCellConfig?

    override func awakeFromNib() {
        super.awakeFromNib()

        configureBackground()
        configureSeparator()
    }

    /// Configure cell
    ///
    func configure(with productImageStatuses: [ProductImageStatus],
                   config: ProductImagesCellConfig,
                   productUIImageLoader: ProductUIImageLoader) {
        let viewModel = ProductImagesHeaderViewModel(productImageStatuses: productImageStatuses,
                                               config: config)
        self.viewModel = viewModel
        dataSource = ProductImagesCollectionViewDataSource(viewModel: viewModel,
                                                           productUIImageLoader: productUIImageLoader)

        configureCollectionView(config: config)

        viewModel.registerCollectionViewCells(collectionView)

        if viewModel.shouldScrollToStart {
            collectionView.scrollToItem(at: IndexPath(item: 0, section: 0), at: .centeredHorizontally, animated: false)
        }
    }

    /// Rotation management
    ///
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection != previousTraitCollection {
            collectionView.collectionViewLayout.invalidateLayout()
            collectionView.reloadData()
        }
    }
}

// MARK: - Collection View Delegate
//
extension ProductImagesHeaderTableViewCell: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        switch viewModel?.items[indexPath.item] {
        case .image(let status):
            switch status {
            case .remote(let image):
                onImageSelected?(image, indexPath)
            default:
                break
            }
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

        switch viewModel?.items[indexPath.item] {
        case .extendedAddImage:
            return frame.size
        default:
            return ProductImagesHeaderViewModel.defaultCollectionViewCellSize
        }
    }
}

/// Cell configurations allowed
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
        backgroundColor = .systemColor(.secondarySystemGroupedBackground)
    }

    func configureSeparator() {
        separatorInset.left = 0
    }

    func configureCollectionView(config: ProductImagesCellConfig) {
        collectionView.delegate = self
        collectionView.dataSource = dataSource
        collectionView.backgroundColor = .systemColor(.secondarySystemGroupedBackground)
        collectionView.showsHorizontalScrollIndicator = false

        guard config != self.config else {
            return
        }

        self.config = config

        switch config {
        case .extendedAddImages:
            collectionView.collectionViewLayout = ProductImagesFlowLayout(itemSize: frame.size, config: config)
        default:
            collectionView.collectionViewLayout = ProductImagesFlowLayout(itemSize: ProductImagesHeaderViewModel.defaultCollectionViewCellSize, config: config)
        }
    }
}
