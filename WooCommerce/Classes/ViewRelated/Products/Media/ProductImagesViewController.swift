import Photos
import UIKit
import Yosemite

/// Displays Product images with edit functionality.
///
final class ProductImagesViewController: UIViewController {
    typealias Completion = (_ images: [ProductImage], _ hasChangedData: Bool) -> Void

    @IBOutlet private weak var addButton: UIButton!
    @IBOutlet private weak var addButtonBottomBorderView: UIView!
    @IBOutlet private weak var imagesContainerView: UIView!

    private let siteID: Int64
    private let productID: Int64
    private let product: ProductFormDataModel

    private let productImageActionHandler: ProductImageActionHandler
    private let productUIImageLoader: ProductUIImageLoader

    private let originalProductImages: [ProductImage]
    private var productImageStatuses: [ProductImageStatus] = []
    private var productImages: [ProductImage] {
        return productImageStatuses.compactMap { status in
            switch status {
            case .remote(let productImage):
                return productImage
            default:
                return nil
            }
        }
    }
    private var productImageStatusesObservationToken: ObservationToken?

    // Child view controller.
    private lazy var imagesViewController: ProductImagesCollectionViewController = {
        let viewController = ProductImagesCollectionViewController(imageStatuses: productImageStatuses,
                                                                   productUIImageLoader: productUIImageLoader,
                                                                   onDeletion: { [weak self] productImage in
                                                                    self?.onDeletion(productImage: productImage)
        })
        return viewController
    }()

    private lazy var mediaPickingCoordinator: MediaPickingCoordinator = {
        return MediaPickingCoordinator(siteID: siteID,
                                       allowsMultipleImages: product.allowsMultipleImages(),
                                       onCameraCaptureCompletion: { [weak self] asset, error in
                                        self?.onCameraCaptureCompletion(asset: asset, error: error)
            }, onDeviceMediaLibraryPickerCompletion: { [weak self] assets in
                self?.onDeviceMediaLibraryPickerCompletion(assets: assets)
            }, onWPMediaPickerCompletion: { [weak self] mediaItems in
                self?.onWPMediaPickerCompletion(mediaItems: mediaItems)
        })
    }()

    private var hasDeletedAnyImages: Bool = false

    private let onCompletion: Completion

    init(product: ProductFormDataModel,
         productImageActionHandler: ProductImageActionHandler,
         productUIImageLoader: ProductUIImageLoader,
         completion: @escaping Completion) {
        self.product = product
        self.siteID = product.siteID
        self.productID = product.productID
        self.productImageActionHandler = productImageActionHandler
        self.productUIImageLoader = productUIImageLoader
        self.originalProductImages = product.images
        self.onCompletion = completion
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        productImageStatusesObservationToken?.cancel()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureMainView()
        configureNavigation()
        configureAddButton()
        configureAddButtonBottomBorderView()
        configureImagesContainerView()
        configureProductImagesObservation()
        handleSwipeBackGesture()
    }
}

// MARK: - UI configurations
//
private extension ProductImagesViewController {
    func configureMainView() {
        view.backgroundColor = .basicBackground
    }

    func configureNavigation() {
        title = NSLocalizedString("Photos", comment: "Product images (Product images page title)")

        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneButtonTapped))

        removeNavigationBackBarButtonText()
    }

    func configureAddButton() {
        updateAddButtonTitle(numberOfImages: product.images.count)
        addButton.addTarget(self, action: #selector(addTapped), for: .touchUpInside)
        addButton.applySecondaryButtonStyle()
    }

    func configureAddButtonBottomBorderView() {
        addButtonBottomBorderView.backgroundColor = .systemColor(.separator)
    }

    func configureImagesContainerView() {
        imagesContainerView.backgroundColor = .basicBackground

        addChild(imagesViewController)
        imagesContainerView.addSubview(imagesViewController.view)
        imagesViewController.didMove(toParent: self)

        imagesViewController.view.translatesAutoresizingMaskIntoConstraints = false
        imagesContainerView.pinSubviewToSafeArea(imagesViewController.view)
    }

    func configureProductImagesObservation() {
        productImageStatusesObservationToken = productImageActionHandler.addUpdateObserver(self) { [weak self] (productImageStatuses, error) in
            guard let self = self else {
                return
            }

            self.productImageStatuses = productImageStatuses

            if let error = error {
                self.displayErrorAlert(error: error)
            }

            self.updateAddButtonTitle(numberOfImages: productImageStatuses.count)

            self.imagesViewController.updateProductImageStatuses(productImageStatuses)
        }
    }
}

// MARK: - Updates
//
private extension ProductImagesViewController {
    func updateAddButtonTitle(numberOfImages: Int) {
        let title: String
        if product.allowsMultipleImages() {
            title = Localization.addPhotos
        } else {
            title = numberOfImages == 0 ? Localization.addPhoto: Localization.replacePhoto
        }
        addButton.setTitle(title, for: .normal)
    }
}

// MARK: - Actions
//
private extension ProductImagesViewController {

    @objc func addTapped() {
        ServiceLocator.analytics.track(.productImageSettingsAddImagesButtonTapped)
        showOptionsMenu()
    }

    @objc func doneButtonTapped() {
        commitAndDismiss(hasOutstandingChanges())
    }

    func deleteExistingImageIfOnlyOneImageIsAllowed() {
        if product.allowsMultipleImages() == false, let currentImage = product.images.first {
            productImageActionHandler.deleteProductImage(currentImage)
        }
    }

    func commitAndDismiss(_ hasChangedData: Bool) {
        onCompletion(productImages, hasChangedData)
    }

    func showOptionsMenu() {
        let pickingContext = MediaPickingContext(origin: self, view: addButton)
        mediaPickingCoordinator.present(context: pickingContext)
    }

    func onDeletion(productImage: ProductImage) {
        hasDeletedAnyImages = true
        productImageActionHandler.deleteProductImage(productImage)
        navigationController?.popViewController(animated: true)
    }
}

// MARK: - Navigation actions handling
//
extension ProductImagesViewController {
    override func shouldPopOnBackButton() -> Bool {
        guard hasOutstandingChanges() == false else {
            presentDiscardChangesActionSheet()
            return false
        }
        return true
    }

    override func shouldPopOnSwipeBack() -> Bool {
        return shouldPopOnBackButton()
    }

    private func presentDiscardChangesActionSheet() {
        UIAlertController.presentDiscardChangesActionSheet(viewController: self, onDiscard: { [weak self] in
            self?.resetProductImages()
            self?.navigationController?.popViewController(animated: true)
        })
    }

    private func resetProductImages() {
        productImageActionHandler.resetProductImages(to: product)
    }

    private func hasOutstandingChanges() -> Bool {
        return hasDeletedAnyImages
    }
}

// MARK: - Image upload to WP Media Library and Product
//
private extension ProductImagesViewController {
    func uploadMediaAssetToSiteMediaLibrary(asset: PHAsset) {
        productImageActionHandler.uploadMediaAssetToSiteMediaLibrary(asset: asset)
    }
}

// MARK: - Action handling for camera capture
//
private extension ProductImagesViewController {
    func onCameraCaptureCompletion(asset: PHAsset?, error: Error?) {
        guard let asset = asset else {
            displayErrorAlert(error: error)
            return
        }
        deleteExistingImageIfOnlyOneImageIsAllowed()
        uploadMediaAssetToSiteMediaLibrary(asset: asset)
        commitAndDismiss(true)
    }
}

// MARK: Action handling for device media library picker
//
private extension ProductImagesViewController {
    func onDeviceMediaLibraryPickerCompletion(assets: [PHAsset]) {
        let shouldAnimateMediaLibraryDismissal = assets.isEmpty
        dismiss(animated: shouldAnimateMediaLibraryDismissal) { [weak self] in
            guard let self = self, assets.isNotEmpty else {
                return
            }

            self.deleteExistingImageIfOnlyOneImageIsAllowed()
            assets.forEach { asset in
                self.uploadMediaAssetToSiteMediaLibrary(asset: asset)
            }
            self.commitAndDismiss(true)
        }
    }
}

// MARK: - Action handling for WordPress Media Library
//
private extension ProductImagesViewController {
    func onWPMediaPickerCompletion(mediaItems: [Media]) {
        let shouldAnimateWPMediaPickerDismissal = mediaItems.isEmpty
        dismiss(animated: shouldAnimateWPMediaPickerDismissal) { [weak self] in
            guard let self = self, mediaItems.isNotEmpty else {
                return
            }

            self.deleteExistingImageIfOnlyOneImageIsAllowed()
            self.productImageActionHandler.addSiteMediaLibraryImagesToProduct(mediaItems: mediaItems)
            self.commitAndDismiss(true)
        }
    }
}

// MARK: Error handling
//
private extension ProductImagesViewController {
    func displayErrorAlert(error: Error?) {
        let title = NSLocalizedString("Cannot upload image", comment: "Title of the alert when there is an error uploading image(s)")
        let alertController = UIAlertController(title: title,
                                                message: error?.localizedDescription,
                                                preferredStyle: .alert)
        let cancel = UIAlertAction(title: NSLocalizedString("OK",
                                                            comment: "Dismiss button on the alert when there is an error uploading image(s)"),
                                   style: .cancel,
                                   handler: nil)
        alertController.addAction(cancel)
        present(alertController, animated: true)
    }
}

private extension ProductImagesViewController {
    enum Localization {
        static let addPhotos = NSLocalizedString("Add Photos", comment: "Action to add photos on the Product images screen")
        static let addPhoto = NSLocalizedString("Add Photo", comment: "Action to add one photo on the Product images screen")
        static let replacePhoto = NSLocalizedString("Replace Photo", comment: "Action to replace one photo on the Product images screen")
    }
}
