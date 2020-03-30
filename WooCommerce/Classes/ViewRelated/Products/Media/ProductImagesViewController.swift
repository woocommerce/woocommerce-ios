import Photos
import UIKit
import Yosemite

/// Displays Product images with edit functionality.
///
final class ProductImagesViewController: UIViewController {
    typealias Completion = (_ images: [ProductImage]) -> Void

    @IBOutlet private weak var addButton: UIButton!
    @IBOutlet private weak var addButtonBottomBorderView: UIView!
    @IBOutlet private weak var imagesContainerView: UIView!

    private let siteID: Int64
    private let productID: Int64

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
                                       onCameraCaptureCompletion: { [weak self] asset, error in
                                        self?.onCameraCaptureCompletion(asset: asset, error: error)
            }, onDeviceMediaLibraryPickerCompletion: { [weak self] assets in
                self?.onDeviceMediaLibraryPickerCompletion(assets: assets)
            }, onWPMediaPickerCompletion: { [weak self] mediaItems in
                self?.onWPMediaPickerCompletion(mediaItems: mediaItems)
        })
    }()

    private let onCompletion: Completion

    init(product: Product,
         productImageActionHandler: ProductImageActionHandler,
         productUIImageLoader: ProductUIImageLoader,
         completion: @escaping Completion) {
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
        addButton.setTitle(NSLocalizedString("Add Photos", comment: "Action to add photos on the Product images screen"), for: .normal)
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

            self.imagesViewController.updateProductImageStatuses(productImageStatuses)
        }
    }
}

// MARK: - Actions
//
private extension ProductImagesViewController {

    @objc func addTapped() {
        showOptionsMenu()
    }

    @objc func doneButtonTapped() {
        onCompletion(productImages)
    }

    func showOptionsMenu() {
        let pickingContext = MediaPickingContext(origin: self, view: addButton)
        mediaPickingCoordinator.present(context: pickingContext)
    }

    func onDeletion(productImage: ProductImage) {
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

    private func presentDiscardChangesActionSheet() {
        UIAlertController.presentDiscardChangesActionSheet(viewController: self, onDiscard: { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        })
    }

    private func hasOutstandingChanges() -> Bool {
        return originalProductImages != productImages
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
        uploadMediaAssetToSiteMediaLibrary(asset: asset)
    }
}

// MARK: Action handling for device media library picker
//
private extension ProductImagesViewController {
    func onDeviceMediaLibraryPickerCompletion(assets: [PHAsset]) {
        defer {
            dismiss(animated: true, completion: nil)
        }
        guard assets.isEmpty == false else {
            return
        }
        assets.forEach { asset in
            uploadMediaAssetToSiteMediaLibrary(asset: asset)
        }
    }
}

// MARK: - Action handling for WordPress Media Library
//
private extension ProductImagesViewController {
    func onWPMediaPickerCompletion(mediaItems: [Media]) {
        dismiss(animated: true, completion: nil)
        productImageActionHandler.addSiteMediaLibraryImagesToProduct(mediaItems: mediaItems)
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
