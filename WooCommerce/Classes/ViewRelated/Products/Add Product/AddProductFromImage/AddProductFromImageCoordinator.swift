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
    private let source: AddProductCoordinator.Source
    private let productName: String?
    private let productImageLoader: ProductUIImageLoader

    /// Invoked when AI generates product data from image
    private let onAIGenerationCompleted: (AddProductFromImageData?) -> Void

    init(siteID: Int64,
         source: AddProductCoordinator.Source,
         productName: String?,
         sourceNavigationController: UINavigationController,
         productImageLoader: ProductUIImageLoader = DefaultProductUIImageLoader(phAssetImageLoaderProvider: { PHImageManager.default() }),
         onAIGenerationCompleted: @escaping (AddProductFromImageData?) -> Void) {
        self.siteID = siteID
        self.source = source
        self.productName = productName
        self.navigationController = sourceNavigationController
        self.productImageLoader = productImageLoader
        self.onAIGenerationCompleted = onAIGenerationCompleted
    }

    func start() {
        let addProductFromImage = AddProductFromImageHostingController(siteID: siteID,
                                                                       source: source,
                                                                       productName: productName,
                                                                       addImage: { [weak self] source in
            await self?.showImagePicker(source: source)
        }, completion: { [weak self] data in
            guard let self else { return }
            Task { @MainActor in
                await self.navigationController.dismiss(animated: true)
                self.onAIGenerationCompleted(data)
            }
        })
        let formNavigationController = UINavigationController(rootViewController: addProductFromImage)
        self.formNavigationController = formNavigationController
        navigationController.present(formNavigationController, animated: true)
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
                                                                  imagesOnly: true,
                                                                  allowsMultipleSelections: false,
                                                                  flow: .productFromImageForm,
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
                    let image = await self.onDeviceMediaLibraryPickerCompletion(assets: assets)
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
        return await requestImage(from: asset)
    }
}

// MARK: Action handling for device media library picker
//
private extension AddProductFromImageCoordinator {
    @MainActor
    func onDeviceMediaLibraryPickerCompletion(assets: [PHAsset]) async -> MediaPickerImage? {
        guard let asset = assets.first else {
            return nil
        }
        return await requestImage(from: asset)
    }
}

// MARK: - Action handling for WordPress Media Library
//
private extension AddProductFromImageCoordinator {
    @MainActor
    func onWPMediaPickerCompletion(mediaItems: [Media]) async -> MediaPickerImage? {
        guard let media = mediaItems.first,
              let image = try? await productImageLoader.requestImage(productImage: media.toProductImage)else {
            return nil
        }
        return .init(image: image, source: .media(media: media))
    }
}

private extension AddProductFromImageCoordinator {
    @MainActor
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
