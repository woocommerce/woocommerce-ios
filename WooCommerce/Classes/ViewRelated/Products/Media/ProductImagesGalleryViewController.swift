import UIKit
import Yosemite
import Photos

/// Displays Product images in sequence, with a delete action.
///
final class ProductImagesGalleryViewController: UIViewController {

    typealias Deletion = (_ productImage: ProductImage) -> Void

    @IBOutlet private weak var collectionView: UICollectionView!

    private var productImages: [ProductImage]

    private let isDeletionEnabled: Bool

    // If present, the collection view will initially show the image at the selected index
    private var selectedIndex: Int?
    private let productUIImageLoader: ProductUIImageLoader
    private let productImageActionHandler: ProductImageActionHandler
    private let onDeletion: Deletion

    private var previousBarTintColor: UIColor?

    // The index of the current visible image
    private var currentImageIndex: Int? {
        return collectionView.indexPathsForVisibleItems.first?.item
    }

    private var productBackgroundFormController: UIViewController?

    init(images: [ProductImage],
         selectedIndex: Int? = nil,
         isDeletionEnabled: Bool,
         productUIImageLoader: ProductUIImageLoader,
         productImageActionHandler: ProductImageActionHandler,
         onDeletion: @escaping Deletion) {
        self.productImages = images
        self.selectedIndex = selectedIndex
        self.isDeletionEnabled = isDeletionEnabled
        self.productUIImageLoader = productUIImageLoader
        self.productImageActionHandler = productImageActionHandler
        self.onDeletion = onDeletion
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureMainView()
        configureNavigation()
        configureCollectionView()
        registerCells()

        scrollToSelectedIndex(index: selectedIndex)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        previousBarTintColor = navigationController?.navigationBar.barTintColor
        navigationController?.navigationBar.barTintColor = .black
    }

    override func viewWillDisappear(_ animated: Bool) {
        navigationController?.navigationBar.barTintColor = previousBarTintColor
        dismissProductGeneratorBottomSheetIfNeeded()
        super.viewWillDisappear(animated)
    }

    private func scrollToSelectedIndex(index: Int?) {
        if let selectedIndex = index {
            let indexPath = IndexPath(item: selectedIndex, section: 0)
            DispatchQueue.main.async {
                self.collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: false)
            }
        }
    }
}

// MARK: Configuration
//
private extension ProductImagesGalleryViewController {
    func configureMainView() {
        view.backgroundColor = .black
    }

    func configureNavigation() {
        guard isDeletionEnabled else {
            return
        }
        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(image: .trashImage,
                            style: .plain,
                            target: self,
                            action: #selector(deleteProductImage)),
            UIBarButtonItem(title: "🪄",
                            style: .plain,
                            target: self,
                            action: #selector(replaceImageBackground))
            ]
    }

    func configureCollectionView() {
        collectionView.backgroundColor = .black
        collectionView.isPagingEnabled = true
        collectionView.showsHorizontalScrollIndicator = false
        if let collectionViewLayout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            collectionViewLayout.scrollDirection = .horizontal
            collectionViewLayout.minimumLineSpacing = 0
            collectionViewLayout.minimumInteritemSpacing = 0
        }
        collectionView.dataSource = self
        collectionView.delegate = self
    }

    func registerCells() {
        collectionView.register(ProductImageCollectionViewCell.loadNib(), forCellWithReuseIdentifier: ProductImageCollectionViewCell.reuseIdentifier)
    }
}

// MARK: Actions
//
private extension ProductImagesGalleryViewController {
    @objc func deleteProductImage() {
        let title = NSLocalizedString("Remove Image",
                                      comment: "Title on the alert when the user taps to delete a Product image")
        let message = NSLocalizedString("Are you sure you want to remove this image?",
                                        comment: "Message on the alert when the user taps to delete a Product image")
        let alert = UIAlertController(title: title,
                                      message: message,
                                      preferredStyle: .alert)
        alert.view.tintColor = .text
        let cancel = UIAlertAction(title: NSLocalizedString(
            "Cancel",
            comment: "Dismiss button on the alert when the user taps to delete a Product image"
        ), style: .cancel, handler: nil)

        let delete = UIAlertAction(title: NSLocalizedString(
            "Remove",
            comment: "Confirm button on the alert when the user taps to delete a Product image"
        ), style: .destructive) { [weak self] _ in
            guard let self = self else {
                return
            }
            if let index = self.currentImageIndex {
                self.onDeletion(self.productImages[index])
                self.productImages.remove(at: index)
                self.collectionView.reloadData()
            }

            if self.productImages.count == 0 {
                self.navigationController?.popViewController(animated: true)
            }
        }

        alert.addAction(cancel)
        alert.addAction(delete)

        ServiceLocator.analytics.track(.productImageSettingsDeleteImageButtonTapped)

        present(alert, animated: true, completion: nil)
    }

    @objc func replaceImageBackground() {
        guard let index = currentImageIndex, let image = productImages[safe: index] else {
            return
        }

        showProductBackgroundFormBottomSheet(productImage: image, prompt: "")
    }

    func showProductBackgroundFormBottomSheet(productImage: ProductImage, prompt: String) {
        let controller = ProductImageBackgroundFormHostingController(viewModel: .init(prompt: prompt,
                                                                                      productImage: productImage,
                                                                                      productUIImageLoader: productUIImageLoader)) { [weak self] image in
            guard let self else { return }
            self.replaceImage(productImage: productImage, with: image)
            self.dismiss(animated: true)
        }
        productBackgroundFormController = controller
        // Disables interactive dismissal of the bottom sheet.
        controller.isModalInPresentation = true
        configureBottomSheetPresentation(for: controller)
        view.endEditing(true)
        present(controller, animated: true)
    }

    func replaceImage(productImage: ProductImage, with newImage: UIImage) {
        productImageActionHandler.uploadImageToSiteMediaLibrary(image: newImage)
    }

    func configureBottomSheetPresentation(for viewController: UIViewController) {
        if let sheet = viewController.sheetPresentationController {
            sheet.prefersEdgeAttachedInCompactHeight = true
            sheet.largestUndimmedDetentIdentifier = .large
            sheet.prefersGrabberVisible = true
            if #available(iOS 16.0, *) {
                sheet.detents = [.custom(resolver: { context in
                    context.maximumDetentValue * 0.2
                }), .medium(), .large()]
            } else {
                sheet.detents = [.medium(), .large()]
            }
        }
    }

    func dismissProductGeneratorBottomSheetIfNeeded() {
        productBackgroundFormController?.dismiss(animated: false) { [weak self] in
            self?.productBackgroundFormController = nil
        }
    }
}

// MARK: CollectionView DataSource
//
extension ProductImagesGalleryViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return productImages.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let image = productImages[indexPath.row]
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ProductImageCollectionViewCell.reuseIdentifier,
                                                      for: indexPath)
        configureRemoteImageCell(cell, productImage: image)
        return cell
    }

}

extension ProductImagesGalleryViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return collectionView.frame.size
    }

    // Scroll to the right index every time viewWillTransitionToSize is called.
    // Then performBatchUpdates to adjust our layout.
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        scrollToSelectedIndex(index: currentImageIndex)
        collectionView.reloadData()
    }
}

// MARK: Cell configuration
//
private extension ProductImagesGalleryViewController {

    func configureRemoteImageCell(_ cell: UICollectionViewCell, productImage: ProductImage) {
        guard let cell = cell as? ProductImageCollectionViewCell else {
            return
        }

        cell.backgroundColor = .black
        cell.imageView.contentMode = .center
        cell.imageView.image = .productsTabProductCellPlaceholderImage
        cell.contentView.layer.borderWidth = 0

        let cancellable = productUIImageLoader.requestImage(productImage: productImage) { [weak cell] image in
            cell?.imageView.contentMode = .scaleAspectFit
            cell?.imageView.image = image
        }
        cell.cancellableTask = cancellable
    }
}
