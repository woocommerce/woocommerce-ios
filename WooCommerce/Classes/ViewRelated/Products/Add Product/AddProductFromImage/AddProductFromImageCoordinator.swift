import Photos
import UIKit
import Yosemite
import WooFoundation

/// Controls navigation for the flow to add a product from an image.
final class AddProductFromImageCoordinator: Coordinator {
    let navigationController: UINavigationController

    /// Navigation controller for the product creation form.
    private var formNavigationController: UINavigationController?

    private var mediaPickingCoordinator: MediaPickingCoordinator?

    private let siteID: Int64
    private let productImageUploader: ProductImageUploaderProtocol
    private let productImageLoader: ProductUIImageLoader

    /// Invoked when a new product is saved remotely.
    private let onProductCreated: (Product) -> Void

    init(siteID: Int64,
         sourceNavigationController: UINavigationController,
         productImageUploader: ProductImageUploaderProtocol = ServiceLocator.productImageUploader,
         productImageLoader: ProductUIImageLoader = DefaultProductUIImageLoader(phAssetImageLoaderProvider: { PHImageManager.default() }),
         onProductCreated: @escaping (Product) -> Void) {
        self.siteID = siteID
        self.navigationController = sourceNavigationController
        self.productImageUploader = productImageUploader
        self.productImageLoader = productImageLoader
        self.onProductCreated = onProductCreated
    }

    func start() {
        let addProductFromImage = AddProductFromImageHostingController(siteID: siteID,
                                                                       addImage: { [weak self] source in
            await self?.showImagePicker(source: source)
        }, completion: { [weak self] data in
            self?.navigationController.dismiss(animated: true) { [weak self] in
                guard let self else { return }
                guard let product = self.createProduct(name: data.name, description: data.description) else {
                    return
                }
                self.showProduct(product, image: data.image)
            }
        })
        let formNavigationController = UINavigationController(rootViewController: addProductFromImage)
        self.formNavigationController = formNavigationController
        navigationController.present(formNavigationController, animated: true)
    }
}

private extension AddProductFromImageCoordinator {
    func createProduct(name: String, description: String?) -> Product? {
        guard let product = ProductFactory().createNewProduct(type: .simple,
                                                              isVirtual: false,
                                                              siteID: siteID)?
            .copy(name: name,
                  fullDescription: description) else {
            return nil
        }
        return product
    }

    /// Shows a product in the current navigation stack.
    func showProduct(_ product: Product, image: MediaPickerImage?) {
        let model = EditableProductModel(product: product)
        let currencyCode = ServiceLocator.currencySettings.currencyCode
        let currency = ServiceLocator.currencySettings.symbol(from: currencyCode)
        let productImageActionHandler = productImageUploader
            .actionHandler(key: .init(siteID: product.siteID,
                                      productOrVariationID: .product(id: model.productID),
                                      isLocalID: true),
                           originalStatuses: [])
        if let image {
            switch image.source {
                case let .asset(asset):
                    productImageActionHandler.uploadMediaAssetToSiteMediaLibrary(asset: asset)
                case let .media(media):
                    productImageActionHandler.addSiteMediaLibraryImagesToProduct(mediaItems: [media])
            }
        }
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
    func showImagePicker(source: MediaPickingSource) async -> MediaPickerImage? {
        guard let formNavigationController else {
            return nil
        }
        return await withCheckedContinuation { continuation in
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
                guard let self else {
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
                    let image = await self.onWPMediaPickerCompletion(mediaItems: mediaItems, navigationController: formNavigationController)
                    continuation.resume(returning: image)
                }
            })
            self.mediaPickingCoordinator = mediaPickingCoordinator
            mediaPickingCoordinator.showMediaPicker(source: source, from: formNavigationController)
        }
    }
}

// MARK: - Action handling for camera capture
//
private extension AddProductFromImageCoordinator {
    @MainActor
    func onCameraCaptureCompletion(asset: PHAsset?, error: Error?) async -> MediaPickerImage? {
        guard let asset else {
            return nil
        }
        return await withCheckedContinuation { continuation in
            Task { @MainActor in
                continuation.resume(returning: await requestImage(from: asset))
            }
        }
    }
}

// MARK: Action handling for device media library picker
//
private extension AddProductFromImageCoordinator {
    @MainActor
    func onDeviceMediaLibraryPickerCompletion(assets: [PHAsset], navigationController: UINavigationController) async -> MediaPickerImage? {
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
    func onWPMediaPickerCompletion(mediaItems: [Media], navigationController: UINavigationController) async -> MediaPickerImage? {
        await withCheckedContinuation { continuation in
            let shouldAnimateMediaLibraryDismissal = mediaItems.isEmpty
            navigationController.dismiss(animated: shouldAnimateMediaLibraryDismissal) { [weak self] in
                guard let self, let media = mediaItems.first else {
                    return continuation.resume(returning: nil)
                }
                let productImage = media.toProductImage
                _ = self.productImageLoader.requestImage(productImage: productImage) { image in
                    continuation.resume(returning: .init(image: image, source: .media(media: media)))
                }
            }
        }
    }
}

private extension AddProductFromImageCoordinator {
    func requestImage(from asset: PHAsset) async -> MediaPickerImage? {
        await withCheckedContinuation { continuation in
            // PHImageManager.requestImageForAsset can be called more than once.
            var hasReceivedImage = false
            productImageLoader.requestImage(asset: asset, targetSize: PHImageManagerMaximumSize, skipsDegradedImage: true) { image in
                guard hasReceivedImage == false else {
                    return
                }
                continuation.resume(returning: .init(image: image, source: .asset(asset: asset)))
                hasReceivedImage = true
            }
        }
    }
}
