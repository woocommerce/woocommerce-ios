import Photos
import UIKit
import Yosemite
import WooFoundation
import protocol Storage.StorageManagerType

/// Controls navigation for the flow to add a product given a navigation controller.
/// This class is not meant to be retained so that its life cycle is throughout the navigation. Example usage:
///
/// let coordinator = AddProductCoordinator(...)
/// coordinator.start()
///
final class AddProductFromImageCoordinator: Coordinator {
    /// Assign this closure to be notified when a new product is saved remotely
    ///
    var onProductCreated: (Product) -> Void = { _ in }

    let navigationController: UINavigationController

    /// Navigation controller for the product creation form.
    private var formNavigationController: UINavigationController?

    private var mediaPickingCoordinator: MediaPickingCoordinator?

    private let siteID: Int64
    private let productImageUploader: ProductImageUploaderProtocol
    private let productImageLoader: ProductUIImageLoader
    private let storage: StorageManagerType
    private let isFirstProduct: Bool

    init(siteID: Int64,
         sourceNavigationController: UINavigationController,
         storage: StorageManagerType = ServiceLocator.storageManager,
         productImageUploader: ProductImageUploaderProtocol = ServiceLocator.productImageUploader,
         productImageLoader: ProductUIImageLoader = DefaultProductUIImageLoader(phAssetImageLoaderProvider: { PHImageManager.default() }),
         isFirstProduct: Bool) {
        self.siteID = siteID
        self.navigationController = sourceNavigationController
        self.productImageUploader = productImageUploader
        self.productImageLoader = productImageLoader
        self.storage = storage
        self.isFirstProduct = isFirstProduct
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func start() {
        guard #available(iOS 16.0, *) else {
            return
        }
        let addProductFromImage = AddProductFromImageHostingController(siteID: siteID, addImage: { [weak self] source in
            guard let self else { return nil }
            return await self.showImagePicker(source: source)
        }, completion: { [weak self] data in
            self?.navigationController.dismiss(animated: true) { [weak self] in
                guard let self else { return }
                guard let product = self.createProduct(name: data.name, description: data.description, sku: data.sku) else {
                    return
                }
                self.showProduct(product)
            }
        })
        let formNavigationController = UINavigationController(rootViewController: addProductFromImage)
        self.formNavigationController = formNavigationController
        navigationController.present(formNavigationController, animated: true)
    }
}

private extension AddProductFromImageCoordinator {
    func createProduct(name: String, description: String?, sku: String?) -> Product? {
        guard let product = ProductFactory().createNewProduct(type: .simple,
                                                              isVirtual: false,
                                                              siteID: siteID)?
            .copy(name: name,
                  fullDescription: description,
                  sku: sku) else {
            return nil
        }
        return product
    }

    /// Shows a product in the current navigation stack.
    func showProduct(_ product: Product) {
        let model = EditableProductModel(product: product)
        let currencyCode = ServiceLocator.currencySettings.currencyCode
        let currency = ServiceLocator.currencySettings.symbol(from: currencyCode)
        let productImageActionHandler = productImageUploader
            .actionHandler(key: .init(siteID: product.siteID,
                                      productOrVariationID: .product(id: model.productID),
                                      isLocalID: true),
                           originalStatuses: model.imageStatuses)
        let viewModel = ProductFormViewModel(product: model,
                                             formType: .add,
                                             productImageActionHandler: productImageActionHandler)
        viewModel.onProductCreated = { [weak self] product in
            guard let self else { return }
            self.onProductCreated(product)
        }
        let viewController = ProductFormViewController(viewModel: viewModel,
                                                       eventLogger: ProductFormEventLogger(),
                                                       productImageActionHandler: productImageActionHandler,
                                                       currency: currency,
                                                       presentationStyle: .navigationStack)
        // Since the Add Product UI could hold local changes, disables the bottom bar (tab bar) to simplify app states.
        viewController.hidesBottomBarWhenPushed = true
        navigationController.pushViewController(viewController, animated: true)
    }
}

// MARK: - Action handling for camera capture
//
private extension AddProductFromImageCoordinator {
    @MainActor
    func showImagePicker(source: MediaPickingSource) async -> UIImage? {
        await withCheckedContinuation { continuation in
            let mediaPickingCoordinator = MediaPickingCoordinator(siteID: siteID,
                                                                  allowsMultipleImages: false,
                                                                  onCameraCaptureCompletion: { [weak self] asset, error in
                guard let self else {
                    return continuation.resume(returning: nil)
                }
                Task { @MainActor in
                    let image = await self.onCameraCaptureCompletion(asset: asset, error: error)
                    continuation.resume(returning: image)
                }
            }, onDeviceMediaLibraryPickerCompletion: { [weak self] assets in
                guard let self, let formNavigationController = self.formNavigationController else {
                    return continuation.resume(returning: nil)
                }
                Task { @MainActor in
                    let image = await self.onDeviceMediaLibraryPickerCompletion(assets: assets, navigationController: formNavigationController)
                    continuation.resume(returning: image)
                }
            }, onWPMediaPickerCompletion: { [weak self] mediaItems in
                guard let self else {
                    return continuation.resume(returning: nil)
                }
                Task { @MainActor in
                    let image = await self.onWPMediaPickerCompletion(mediaItems: mediaItems)
                    continuation.resume(returning: image)
                }
            })
            self.mediaPickingCoordinator = mediaPickingCoordinator
            let topViewController = navigationController.topmostPresentedViewController
            mediaPickingCoordinator.showMediaPicker(source: source, from: topViewController)
        }
    }
}

// MARK: - Action handling for camera capture
//
private extension AddProductFromImageCoordinator {
    func onCameraCaptureCompletion(asset: PHAsset?, error: Error?) async -> UIImage? {
        guard let asset else {
            return nil
        }
        return await withCheckedContinuation { continuation in
            Task { @MainActor in
                continuation.resume(returning: await self.requestImage(from: asset))
            }
        }
    }
}

// MARK: Action handling for device media library picker
//
private extension AddProductFromImageCoordinator {
    @MainActor
    func onDeviceMediaLibraryPickerCompletion(assets: [PHAsset], navigationController: UINavigationController) async -> UIImage? {
        await withCheckedContinuation { continuation in
            let shouldAnimateMediaLibraryDismissal = assets.isEmpty
            navigationController.dismiss(animated: shouldAnimateMediaLibraryDismissal) { [weak self] in
                guard let self, let asset = assets.first else {
                    return continuation.resume(returning: nil)
                }
                Task { @MainActor in
                    continuation.resume(returning: await self.requestImage(from: asset))
                }
            }
        }
    }
}

// MARK: - Action handling for WordPress Media Library
//
private extension AddProductFromImageCoordinator {
    @MainActor
    func onWPMediaPickerCompletion(mediaItems: [Media]) async -> UIImage? {
        await withCheckedContinuation { continuation in
            let shouldAnimateMediaLibraryDismissal = mediaItems.isEmpty
            navigationController.dismiss(animated: shouldAnimateMediaLibraryDismissal) { [weak self] in
                guard let self, let media = mediaItems.first else {
                    return continuation.resume(returning: nil)
                }
                let productImage = media.toProductImage
                _ = self.productImageLoader.requestImage(productImage: productImage) { image in
                    continuation.resume(returning: image)
                }
            }
        }
    }
}

private extension AddProductFromImageCoordinator {
    func requestImage(from asset: PHAsset) async -> UIImage? {
        await withCheckedContinuation { continuation in
            // PHImageManager.requestImageForAsset can be called more than onoce
            var hasReceivedImage = false
            productImageLoader.requestImage(asset: asset, targetSize: PHImageManagerMaximumSize) { image in
                guard hasReceivedImage == false else {
                    return
                }
                continuation.resume(returning: image)
                hasReceivedImage = true
            }
        }
    }
}
