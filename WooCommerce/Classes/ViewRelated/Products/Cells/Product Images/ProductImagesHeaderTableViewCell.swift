import UIKit
import Yosemite

final class ProductImagesHeaderTableViewCell: UITableViewCell {

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var collectionViewHeightConstraint: NSLayoutConstraint!

    /// View Model
    ///
    private var viewModel: ProductImagesHeaderViewModel?

    /// Collection View Datasource
    ///
    private var dataSource: ProductImagesCollectionViewDataSource?

    /// Closure to be executed when a image cell is tapped
    ///
    var onImageSelected: ((ProductImage?, IndexPath?) -> Void)?

    /// Closure to be executed when a failed upload is tapped
    ///
    var onFailedUploadSelected: ((_ asset: ProductImageAssetType, _ error: Error) -> Void)?

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
        updateCollectionViewHeight()
        observeInterfaceTraitChanges()
    }

    /// Configure cell
    ///
    func configure(with productImageStatuses: [ProductImageStatus],
                   config: ProductImagesCellConfig,
                   productUIImageLoader: ProductUIImageLoader
                    ) {
        let viewModel = ProductImagesHeaderViewModel(productImageStatuses: productImageStatuses, config: config)
        self.viewModel = viewModel
        dataSource = ProductImagesCollectionViewDataSource(viewModel: viewModel,
                                                           productUIImageLoader: productUIImageLoader)
        configureCollectionView(config: config)
        viewModel.registerCollectionViewCells(collectionView)

        if viewModel.shouldScrollToStart {
            collectionView.scrollToItem(at: IndexPath(item: 0, section: 0), at: .centeredHorizontally, animated: false)
        }
    }

    /// Updates the collection view height based on current accessibility settings
    private func updateCollectionViewHeight() {
        let cellSize = ProductImagesHeaderViewModel.cellSize(for: traitCollection.preferredContentSizeCategory)
        // Add padding to accommodate the cell size
        collectionViewHeightConstraint.constant = cellSize.height + Layout.collectionViewPadding
    }
}

// MARK: - Collection View Delegate
//
extension ProductImagesHeaderTableViewCell: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        switch viewModel?.items[indexPath.item] {
        case .image(let status):
            switch status {
            case .remote(let image, _, _):
                onImageSelected?(image, indexPath)
            case .uploading:
                onImageSelected?(nil, indexPath)
            case let .uploadFailure(asset, error, _, _):
                onFailedUploadSelected?(asset, error)
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
            // Use dynamic sizing based on current accessibility settings
            return ProductImagesHeaderViewModel.cellSize(for: traitCollection.preferredContentSizeCategory)
        }
    }
}

/// Cell configurations allowed
///
enum ProductImagesCellConfig: Equatable {

        // only images
        case images

        // images + add image cell
        case addImages

        // only the extended add image cell
        case extendedAddImages(isVariation: Bool)

}

/// Private Methods
private extension ProductImagesHeaderTableViewCell {
    func configureBackground() {
        backgroundColor = .systemColor(.secondarySystemGroupedBackground)
    }

    func configureSeparator() {
        separatorInset.left = 0
        hideSeparator()
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

        // Update height for the new configuration
        updateCollectionViewHeight()

        switch config {
        case .extendedAddImages:
            collectionView.collectionViewLayout = ProductImagesFlowLayout(itemSize: frame.size, config: config)
        default:
            // Use dynamic sizing based on current accessibility settings
            let dynamicSize = ProductImagesHeaderViewModel.cellSize(for: traitCollection.preferredContentSizeCategory)
            collectionView.collectionViewLayout = ProductImagesFlowLayout(itemSize: dynamicSize, config: config)
        }
    }

    /// Rotation management and accessibility changes
    ///
    func observeInterfaceTraitChanges() {
        let traits: [UITrait] = [
            UITraitPreferredContentSizeCategory.self,
            UITraitHorizontalSizeClass.self,
            UITraitVerticalSizeClass.self,
            UITraitUserInterfaceStyle.self,
            UITraitAccessibilityContrast.self
        ]
        registerForTraitChanges(traits) { (self: Self, previousTraitCollection: UITraitCollection) in
            guard self.traitCollection != previousTraitCollection else {
                return
            }

            /// Update collection view height for accessibility changes
            self.updateCollectionViewHeight()
            /// Invalidate layout when trait collection changes (including accessibility changes)
            self.collectionView.collectionViewLayout.invalidateLayout()
            self.collectionView.reloadData()
        }
    }
}

private extension ProductImagesHeaderTableViewCell {
    enum Layout {
        /// Padding around the collection view (16pt top and bottom)
        static let collectionViewPadding: CGFloat = 32
    }
}
