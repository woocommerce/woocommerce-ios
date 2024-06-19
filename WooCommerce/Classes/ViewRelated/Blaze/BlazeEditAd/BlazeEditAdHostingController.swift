import Photos
import SwiftUI
import Yosemite

/// Blaze ad data for the "Edit Ad Screen" form
struct BlazeEditAdData: Equatable {
    let image: MediaPickerImage?
    let tagline: String
    let description: String
}

/// Hosting controller for `BlazeEditAdView`.
final class BlazeEditAdHostingController: UIHostingController<BlazeEditAdView> {
    private var mediaPickingCoordinator: MediaPickingCoordinator?
    private let productImageLoader: ProductUIImageLoader
    private let siteID: Int64

    init(viewModel: BlazeEditAdViewModel,
         productImageLoader: ProductUIImageLoader = DefaultProductUIImageLoader(phAssetImageLoaderProvider: { PHImageManager.default() })) {
        self.productImageLoader = productImageLoader
        self.siteID = viewModel.siteID
        super.init(rootView: BlazeEditAdView(viewModel: viewModel))
        viewModel.onAddImage = { [weak self] source in
            await self?.showImagePicker(source: source)
        }
    }

    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension BlazeEditAdHostingController {
    @MainActor
    func showImagePicker(source: MediaPickingSource) async -> MediaPickerImage? {
        await withCheckedContinuation { continuation in
            let mediaPickingCoordinator = MediaPickingCoordinator(siteID: siteID,
                                                                  imagesOnly: true,
                                                                  allowsMultipleSelections: false,
                                                                  flow: .blazeEditAdForm,
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
            mediaPickingCoordinator.showMediaPicker(source: source, from: self)
        }
    }
}

// MARK: - Action handling for camera capture
//
private extension BlazeEditAdHostingController {
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
private extension BlazeEditAdHostingController {
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
private extension BlazeEditAdHostingController {
    @MainActor
    func onWPMediaPickerCompletion(mediaItems: [Media]) async -> MediaPickerImage? {
        guard let media = mediaItems.first,
              let image = try? await productImageLoader.requestImage(productImage: media.toProductImage)else {
            return nil
        }

        return .init(image: image, source: .media(media: media))
    }
}

private extension BlazeEditAdHostingController {
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
