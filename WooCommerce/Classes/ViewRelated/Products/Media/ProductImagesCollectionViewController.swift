import Photos
import UIKit
import Yosemite

/// Displays Product images in grid layout.
///
final class ProductImagesCollectionViewController: UICollectionViewController {

    typealias ReorderingHandler = (_ productImageStatuses: [ProductImageStatus]) -> Void

    private var productImageStatuses: [ProductImageStatus]

    private var coordinator: ProductImageEditMenuCoordinator?

    private let isDeletionEnabled: Bool
    private let productUIImageLoader: ProductUIImageLoader
    private let actionHandler: ProductImageActionHandlerProtocol
    private let onDeletion: ProductImagesGalleryViewController.Deletion
    private let onReordering: ReorderingHandler

    init(imageStatuses: [ProductImageStatus],
         isDeletionEnabled: Bool,
         productUIImageLoader: ProductUIImageLoader,
         actionHandler: ProductImageActionHandlerProtocol,
         onDeletion: @escaping ProductImagesGalleryViewController.Deletion,
         onReordering: @escaping ReorderingHandler) {
        self.productImageStatuses = imageStatuses
        self.isDeletionEnabled = isDeletionEnabled
        self.productUIImageLoader = productUIImageLoader
        self.actionHandler = actionHandler
        self.onDeletion = onDeletion
        self.onReordering = onReordering
        let columnLayout = ColumnFlowLayout(
            cellsPerRow: 2,
            minimumInteritemSpacing: 16,
            minimumLineSpacing: 16,
            sectionInset: UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        )
        super.init(collectionViewLayout: columnLayout)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureCollectionView()

        collectionView.reloadData()
    }

    func updateProductImageStatuses(_ productImageStatuses: [ProductImageStatus]) {
        self.productImageStatuses = productImageStatuses

        collectionView.reloadData()
        updateDragAndDropSupport()
    }
}

// MARK: UICollectionViewDataSource
//
extension ProductImagesCollectionViewController {

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return productImageStatuses.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let productImageStatus = productImageStatuses[indexPath.row]
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: productImageStatus.cellReuseIdentifier,
                                                      for: indexPath)
        configureCell(cell, productImageStatus: productImageStatus)
        return cell
    }
}

// MARK: Cell configurations
//
private extension ProductImagesCollectionViewController {
    func configureCell(_ cell: UICollectionViewCell, productImageStatus: ProductImageStatus) {
        switch productImageStatus {
        case .remote(let image):
            configureRemoteImageCell(cell, productImage: image)
        case .uploading(let asset):
            switch asset {
                case .phAsset(let asset):
                    configureUploadingImageCell(cell, asset: asset)
                case .uiImage(let image, _, _):
                    configureUploadingImageCell(cell, image: image)
            }
        }
    }

    func configureRemoteImageCell(_ cell: UICollectionViewCell, productImage: ProductImage) {
        guard let cell = cell as? ProductImageCollectionViewCell else {
            fatalError()
        }

        cell.imageView.contentMode = .center
        cell.imageView.image = .productsTabProductCellPlaceholderImage

        let cancellable = productUIImageLoader.requestImage(productImage: productImage) { [weak cell] image in
            cell?.imageView.contentMode = .scaleAspectFit
            cell?.imageView.image = image
        }
        cell.cancellableTask = cancellable

        // TODO-jc: editable check
        if #available(iOS 17.0, *), isDeletionEnabled {
            let removeBackgroundAction = UIAction(title: "Remove background",
                                                  image: .sparklesImage) { [weak self] _ in
                self?.removeBackground(image: productImage)
            }
            let menu = UIMenu(title: "", children: [removeBackgroundAction])
            cell.setEditButtonMenu(menu)
        } else {
            cell.setEditButtonMenu(nil)
        }
    }

    func configureUploadingImageCell(_ cell: UICollectionViewCell, asset: PHAsset) {
        guard let cell = cell as? InProgressProductImageCollectionViewCell else {
            fatalError()
        }

        cell.imageView.contentMode = .center
        cell.imageView.image = .productsTabProductCellPlaceholderImage

        productUIImageLoader.requestImage(asset: asset, targetSize: cell.bounds.size) { [weak cell] image in
            cell?.imageView.contentMode = .scaleAspectFit
            cell?.imageView.image = image
        }
    }

    func configureUploadingImageCell(_ cell: UICollectionViewCell, image: UIImage) {
        guard let cell = cell as? InProgressProductImageCollectionViewCell else {
            fatalError()
        }

        cell.imageView.contentMode = .scaleAspectFit
        cell.imageView.image = image
    }
}

// MARK: UICollectionViewDelegate
//
extension ProductImagesCollectionViewController {
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let status = productImageStatuses[indexPath.row]
        switch status {
        case .remote:
            break
        default:
            return
        }

        let selectedImageIndex: Int = {
            // In case of any pending images, deduct the number of pending images from the index.
            let imageStatusIndex = indexPath.row
            let numberOfPendingImages = productImageStatuses.count - productImageStatuses.images.count
            return imageStatusIndex - numberOfPendingImages
        }()
        let productImagesGalleryViewController = ProductImagesGalleryViewController(images: productImageStatuses.images,
                                                                                    selectedIndex: selectedImageIndex,
                                                                                    isDeletionEnabled: isDeletionEnabled,
                                                                                    productUIImageLoader: productUIImageLoader) { [weak self] (productImage) in
                                                                                        self?.onDeletion(productImage)
        }
        navigationController?.show(productImagesGalleryViewController, sender: self)
    }
}

/// Drag & Drop support
///
extension ProductImagesCollectionViewController: UICollectionViewDragDelegate, UICollectionViewDropDelegate {
    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        guard let item = productImageStatuses[safe: indexPath.row] else {
            return []
        }
        let dragItem = dragItem(for: item)
        return [dragItem]
    }

    func collectionView(_ collectionView: UICollectionView, dragSessionIsRestrictedToDraggingApplication session: UIDragSession) -> Bool {
        // Dropping photos from external apps is not allowed yet.
        return true
    }

    func collectionView(_ collectionView: UICollectionView,
                        dropSessionDidUpdate session: UIDropSession,
                        withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
        return UICollectionViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
    }

    func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
        guard let destinationIndexPath = coordinator.destinationIndexPath else {
            return
        }

        coordinator.items.forEach { dropItem in
            reorder(dropItem, to: destinationIndexPath, with: coordinator)
        }
    }

    /// Indicates whether the collection view supports moving items.
    ///
    private var isReorderingEnabled: Bool {
        productImageStatuses.containsMoreThanOne
    }

    /// Enables/disables collection view drag interaction.
    ///
    private func updateDragAndDropSupport() {
        collectionView.dragInteractionEnabled = isReorderingEnabled
    }

    /// Returns a `UIDragItem` from a given product image.
    ///
    private func dragItem(for productImageStatus: ProductImageStatus) -> UIDragItem {
        let itemProvider = NSItemProvider(object: NSString(string: productImageStatus.dragItemIdentifier))
        return UIDragItem(itemProvider: itemProvider)
    }

    /// Removes the product image at the given source index and inserts it
    /// at the given destination index.
    ///
    private func moveProductImageStatus(from sourceIndex: Int, to destinationIndex: Int) {
        let imageStatus = productImageStatuses[sourceIndex]
        productImageStatuses.remove(at: sourceIndex)
        productImageStatuses.insert(imageStatus, at: destinationIndex)
    }

    /// Moves an item (`ProductImageStatus`) in the collection view from one index path to another index path.
    ///
    private func reorder(_ item: UICollectionViewDropItem, to destinationIndexPath: IndexPath, with coordinator: UICollectionViewDropCoordinator) {
        guard let sourceIndexPath = item.sourceIndexPath else {
            return
        }

        moveProductImageStatus(from: sourceIndexPath.item, to: destinationIndexPath.item)

        collectionView.performBatchUpdates({
            collectionView.deleteItems(at: [sourceIndexPath])
            collectionView.insertItems(at: [destinationIndexPath])
        }, completion: { [weak self] _ in
            // [Workaround] Reload the collection view if there are more than
            // one type of cells, for example, when there are any pending upload.
            self?.reloadCollectionViewIfNeeded()
        })

        coordinator.drop(item.dragItem, toItemAt: destinationIndexPath)
        onReordering(productImageStatuses)
    }

    /// Reloads collection view only if there is any pending upload.
    /// This makes sure that cells for pending uploads are reloaded properly 
    /// to remove their overlays after uploading is done. 
    ///
    private func reloadCollectionViewIfNeeded() {
        if productImageStatuses.hasPendingUpload {
            collectionView.reloadData()
        }
    }
}

/// View configuration
///
private extension ProductImagesCollectionViewController {
    func configureCollectionView() {
        collectionView.backgroundColor = .basicBackground

        collectionView.dragDelegate = self
        collectionView.dropDelegate = self

        registerCollectionViewCells()
    }

    func registerCollectionViewCells() {
        collectionView.register(ProductImageCollectionViewCell.loadNib(),
                                forCellWithReuseIdentifier: ProductImageCollectionViewCell.reuseIdentifier)
        collectionView.register(InProgressProductImageCollectionViewCell.loadNib(),
                                forCellWithReuseIdentifier: InProgressProductImageCollectionViewCell.reuseIdentifier)
    }
}

private extension ProductImagesCollectionViewController {
    func removeBackground(image: ProductImage) {
        print("\(image)")

        guard let navigationController else {
            return
        }
        let imageLoader = DefaultProductUIImageLoader(phAssetImageLoaderProvider: {
            PHImageManager.default()
        })
        let coordinator = ProductImageEditMenuCoordinator(navigationController: navigationController,
                                                          productImage: image,
                                                          imageLoader: imageLoader,
                                                          actionHandler: actionHandler)
        self.coordinator = coordinator
        coordinator.start()
    }
}

extension ProductImagesCollectionViewController {
    override func collectionView(_ collectionView: UICollectionView,
                                 contextMenuConfigurationForItemsAt indexPaths: [IndexPath],
                                 point: CGPoint) -> UIContextMenuConfiguration? {
        // Multi-selection is not supported.
        guard let indexPath = indexPaths.first, indexPaths.count == 1 else {
            return nil
        }

        guard case let .remote(image) = productImageStatuses[indexPath.row] else {
            return nil
        }

        return UIContextMenuConfiguration(identifier: nil, previewProvider: { nil }, actionProvider: { suggestedActions in
            let removeBackgroundAction = UIAction(title: NSLocalizedString("Remove background", comment: ""),
                                                  image: .sparklesImage) { [weak self] action in
                self?.removeBackground(image: image)
            }
            return UIMenu(title: "", children: [removeBackgroundAction])
        })
    }
}
