import Photos
import UIKit
import Yosemite
import WooFoundation

/// Controls navigation for the flow to select a package photo
///
final class SelectPackageImageCoordinator: Coordinator {
    let navigationController: UINavigationController
    private var mediaPickingCoordinator: MediaPickingCoordinator?
    private let siteID: Int64
    private let mediaSource: MediaPickingSource
    private let productImageLoader: ProductUIImageLoader
    private let onImageSelected: (MediaPickerImage?) -> Void

    init(siteID: Int64,
         mediaSource: MediaPickingSource,
         sourceNavigationController: UINavigationController,
         productImageLoader: ProductUIImageLoader = DefaultProductUIImageLoader(phAssetImageLoaderProvider: { PHImageManager.default() }),
         onImageSelected: @escaping (MediaPickerImage?) -> Void) {
        self.siteID = siteID
        self.mediaSource = mediaSource
        self.navigationController = sourceNavigationController
        self.productImageLoader = productImageLoader
        self.onImageSelected = onImageSelected
    }

    func start() {
        let mediaPickingCoordinator = MediaPickingCoordinator(siteID: siteID,
                                                              imagesOnly: true,
                                                              allowsMultipleSelections: false,
                                                              flow: .readTextFromProductPhoto,
                                                              onCameraCaptureCompletion: { [weak self] asset, error in
            guard let self else { return }

            Task { @MainActor in
                let image = await self.onCameraCaptureCompletion(asset: asset, error: error)
                self.onImageSelected(image)
            }
        }, onDeviceMediaLibraryPickerCompletion: { [weak self] assets in
            guard let self else { return }

            Task { @MainActor in
                let image = await self.onDeviceMediaLibraryPickerCompletion(assets: assets)
                self.onImageSelected(image)
            }
        }, onWPMediaPickerCompletion: { [weak self] mediaItems in
            guard let self else { return }

            Task { @MainActor in
                let image = await self.onWPMediaPickerCompletion(mediaItems: mediaItems)
                self.onImageSelected(image)
            }
        })
        self.mediaPickingCoordinator = mediaPickingCoordinator
        mediaPickingCoordinator.showMediaPicker(source: mediaSource, from: navigationController)
    }
}

// MARK: - Action handling for camera capture
//
private extension SelectPackageImageCoordinator {
    @MainActor
    func onCameraCaptureCompletion(asset: PHAsset?, error: Error?) async -> MediaPickerImage? {
        guard let asset else {
            displayErrorAlert(error: error)
            return nil
        }
        return await requestImage(from: asset)
    }
}

// MARK: Action handling for device media library picker
//
private extension SelectPackageImageCoordinator {
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
private extension SelectPackageImageCoordinator {
    @MainActor
    func onWPMediaPickerCompletion(mediaItems: [Media]) async -> MediaPickerImage? {
        guard let media = mediaItems.first,
              let image = try? await productImageLoader.requestImage(productImage: media.toProductImage)else {
            return nil
        }
        return .init(image: image, source: .media(media: media))
    }
}

// MARK: Error handling
//
private extension SelectPackageImageCoordinator {
    @MainActor
    func displayErrorAlert(error: Error?) {
        let alertController = UIAlertController(title: Localization.ImageErrorAlert.title,
                                                message: error?.localizedDescription,
                                                preferredStyle: .alert)
        let cancel = UIAlertAction(title: Localization.ImageErrorAlert.ok,
                                   style: .cancel,
                                   handler: nil)
        alertController.addAction(cancel)
        navigationController.present(alertController, animated: true)
    }
}

private extension SelectPackageImageCoordinator {
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

private extension SelectPackageImageCoordinator {
    enum Localization {
        enum ImageErrorAlert {
            static let title = NSLocalizedString(
                "selectPackageImageCoordinator.imageErrorAlert.title",
                value: "Unable to select image",
                comment: "Title of the alert when there is an error selecting image"
            )
            static let ok = NSLocalizedString(
                "selectPackageImageCoordinator.imageErrorAlert.ok",
                value: "OK",
                comment: "Dismiss button on the alert when there is an error selecting image"
            )
        }
    }
}
