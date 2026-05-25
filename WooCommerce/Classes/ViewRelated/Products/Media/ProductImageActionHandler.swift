import Combine
import Photos
import Yosemite

/// Interface of `ProductImageActionHandler` to allow mocking in unit tests.
protocol ProductImageActionHandlerProtocol {
    typealias OnAllStatusesUpdate = ([ProductImageStatus]) -> Void
    typealias OnAssetUpload = (ProductImageAssetType, Result<ProductImage, Error>) -> Void

    var productImageStatuses: [ProductImageStatus] { get }

    @discardableResult
    func addUpdateObserver<T: AnyObject>(_ observer: T,
                                         onUpdate: @escaping OnAllStatusesUpdate) -> AnyCancellable

    func addAssetUploadObserver<T: AnyObject>(_ observer: T,
                                              onAssetUpload: @escaping OnAssetUpload) -> AnyCancellable

    func addSiteMediaLibraryImagesToProduct(mediaItems: [Media])

    func uploadMediaAssetToSiteMediaLibrary(asset: ProductImageAssetType)

    func updateProductID(_ remoteProductID: ProductOrVariationID)

    func deleteProductImage(_ productImage: ProductImage)

    func resetProductImages(to product: ProductFormDataModel)

    func updateProductImageStatusesAfterReordering(_ productImageStatuses: [ProductImageStatus])

    func discardUpload(asset: ProductImageAssetType)
}

/// Encapsulates the implementation of Product images actions from the UI.
///
final class ProductImageActionHandler: ProductImageActionHandlerProtocol {
    typealias OnAllStatusesUpdate = ([ProductImageStatus]) -> Void
    typealias OnAssetUpload = (ProductImageAssetType, Result<ProductImage, Error>) -> Void

    private let siteID: Int64
    private var productOrVariationID: ProductOrVariationID

    /// The queue where internal states like `allStatuses` and `observations` are updated on to maintain thread safety.
    private let queue: DispatchQueue

    private let stores: StoresManager

    private(set) var productImageStatuses: [ProductImageStatus] {
        didSet {
            queue.async { [weak self] in
                guard let self else {
                    return
                }
                self.observations.allStatusesUpdated.values.forEach { closure in
                    closure(self.productImageStatuses)
                }
            }
        }
    }

    private var observations = (
        allStatusesUpdated: [UUID: OnAllStatusesUpdate](),
        assetUploaded: [UUID: OnAssetUpload]()
    )

    /// - Parameters:
    ///   - siteID: the ID of a site/store where the product belongs to.
    ///   - productID: the ID of the product whose image statuses and actions are of concern.
    ///   - imageStatuses: the current image statuses of the product.
    ///   - queue: the queue where the update callbacks are called on. Default to be the main queue.
    ///   - stores: stores that dispatch image upload action.
    init(siteID: Int64,
         productID: ProductOrVariationID,
         imageStatuses: [ProductImageStatus],
         queue: DispatchQueue = .main,
         stores: StoresManager = ServiceLocator.stores) {
        self.siteID = siteID
        self.productOrVariationID = productID
        self.queue = queue
        self.stores = stores
        self.productImageStatuses = imageStatuses
    }

    /// Observes when the image statuses have been updated.
    ///
    /// - Parameters:
    ///   - observer: the observer that `onUpdate` is associated with.
    ///   - onUpdate: called when the image statuses have been updated on the thread passed in the initializer (default to the main thread),
    ///               if `observer` is not nil.
    @discardableResult
    func addUpdateObserver<T: AnyObject>(_ observer: T,
                                         onUpdate: @escaping OnAllStatusesUpdate) -> AnyCancellable {
        let id = UUID()

        queue.async { [weak self] in
            guard let self else {
                return
            }

            self.observations.allStatusesUpdated[id] = { [weak self, weak observer] allStatuses in
                guard let self else {
                    return
                }

                // If the observer has been deallocated, we can
                // automatically remove the observation closure.
                guard observer != nil else {
                    self.observations.allStatusesUpdated.removeValue(forKey: id)
                    return
                }

                onUpdate(self.productImageStatuses)
            }

            // Sends the initial value.
            onUpdate(self.productImageStatuses)
        }

        return AnyCancellable { [weak self] in
            self?.queue.async { [weak self] in
                self?.observations.allStatusesUpdated.removeValue(forKey: id)
            }
        }
    }

    /// Observes when an asset has been uploaded.
    ///
    /// - Parameters:
    ///   - observer: the observer that `onAssetUpload` is associated with.
    ///   - onAssetUpload: called when an asset has been uploaded, if `observer` is not nil.
    func addAssetUploadObserver<T: AnyObject>(_ observer: T,
                                              onAssetUpload: @escaping OnAssetUpload) -> AnyCancellable {
        let id = UUID()

        queue.async { [weak self] in
            guard let self else {
                return
            }

            self.observations.assetUploaded[id] = { [weak self, weak observer] asset, result in
                // If the observer has been deallocated, we can
                // automatically remove the observation closure.
                guard observer != nil else {
                    self?.observations.assetUploaded.removeValue(forKey: id)
                    return
                }

                onAssetUpload(asset, result)
            }
        }

        return AnyCancellable { [weak self] in
            self?.queue.async { [weak self] in
                self?.observations.assetUploaded.removeValue(forKey: id)
            }
        }
    }

    func addSiteMediaLibraryImagesToProduct(mediaItems: [Media]) {
        queue.async { [weak self] in
            guard let self else {
                return
            }

            let newProductImageStatuses = mediaItems.map { ProductImageStatus.remote(image: $0.toProductImage,
                                                                                     siteID: self.siteID,
                                                                                     productID: self.productOrVariationID) }
            let imageStatuses = newProductImageStatuses + self.productImageStatuses
            self.productImageStatuses = imageStatuses
        }
    }

    func uploadMediaAssetToSiteMediaLibrary(asset: ProductImageAssetType) {
        queue.async { [weak self] in
            guard let self else {
                return
            }
            let uploadingStatus = ProductImageStatus.uploading(asset: asset, siteID: self.siteID, productID: self.productOrVariationID)

            // If the product is a variation, substitute the existing status with the new uploading status.
            // Otherwise, if a standard product, append a new status.
            if case .variation = self.productOrVariationID {
                self.productImageStatuses = [uploadingStatus]
            } else {
                self.productImageStatuses = [uploadingStatus] + self.productImageStatuses
            }

            self.uploadMediaAssetToSiteMediaLibrary(asset: asset) { [weak self] result in
                                                self?.queue.async { [weak self] in
                                                    guard let self else {
                                                        return
                                                    }

                                                    guard let index = self.index(of: asset) else {
                                                        return
                                                    }

                                                    switch result {
                                                    case .success(let media):
                                                        let productImage = ProductImage(imageID: media.mediaID,
                                                                                        dateCreated: media.date,
                                                                                        dateModified: media.date,
                                                                                        src: media.src,
                                                                                        name: media.name,
                                                                                        alt: media.alt)
                                                        self.updateProductImageStatus(at: index, productImage: productImage)
                                                    case .failure(let error):
                                                        ServiceLocator.analytics.track(.productImageUploadFailed, withError: error)
                                                        self.updateProductImageStatus(at: index, error: error)
                                                    }
                                                }
            }
        }
    }

    private func uploadMediaAssetToSiteMediaLibrary(asset: ProductImageAssetType, onCompletion: @escaping (Result<Media, Error>) -> Void) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            let action: MediaAction
            switch asset {
                case .phAsset(let asset):
                    action = MediaAction.uploadMedia(siteID: self.siteID,
                                                     productID: self.productOrVariationID.id,
                                                     mediaAsset: asset,
                                                     altText: nil,
                                                     filename: nil,
                                                     onCompletion: onCompletion)
                case .uiImage(let image, let filename, let altText):
                    action = MediaAction.uploadMedia(siteID: self.siteID,
                                                     productID: self.productOrVariationID.id,
                                                     mediaAsset: image,
                                                     altText: altText,
                                                     filename: filename,
                                                     onCompletion: onCompletion)
            }
            self.stores.dispatch(action)
        }
    }

    func discardUpload(asset: ProductImageAssetType) {
        queue.async { [weak self] in
            guard let self else { return }

            guard let uploadIndex = index(of: asset) else {
                DDLogWarn("⚠️ Could not find upload for asset to discard!")
                return
            }

            productImageStatuses.remove(at: uploadIndex)
        }
    }

    /// Updates the `productID` with the provided `remoteProductID`
    ///
    /// Used for updating the product ID during create product flow. i.e. To replace the local product ID with the remote product ID.
    ///
    func updateProductID(_ remoteProductID: ProductOrVariationID) {
        queue.async { [weak self] in
            guard let self else {
                return
            }
            self.productOrVariationID = remoteProductID
            self.productImageStatuses = self.productImageStatuses.map { status in
                switch status {
                case .uploading(let asset, let siteID, _):
                    return .uploading(asset: asset, siteID: siteID, productID: remoteProductID)
                case .uploadFailure(let asset, let error, let siteID, _):
                    return .uploadFailure(asset: asset, error: error, siteID: siteID, productID: remoteProductID)
                default:
                    return status
                }
            }
        }
    }

    func deleteProductImage(_ productImage: ProductImage) {
        queue.async { [weak self] in
            guard let self else {
                return
            }

            var imageStatuses = self.productImageStatuses
            imageStatuses.removeAll { status -> Bool in
                guard case .remote(let image, let siteID, let productID) = status else {
                    return false
                }
                return image.imageID == productImage.imageID && siteID == self.siteID && productID == self.productOrVariationID
            }
            self.productImageStatuses = imageStatuses
        }
    }

    /// Resets the product images to the ones from the given Product.
    ///
    func resetProductImages(to product: ProductFormDataModel) {
        queue.async { [weak self] in
            guard let self else {
                return
            }

            self.productImageStatuses = product.imageStatuses
        }
    }

    /// Updates the product images with the given ones.
    ///
    func updateProductImageStatusesAfterReordering(_ productImageStatuses: [ProductImageStatus]) {
        queue.async { [weak self] in
            guard let self else {
                return
            }

            self.productImageStatuses = productImageStatuses
        }
    }
}

private extension ProductImageActionHandler {
    func index(of asset: ProductImageAssetType) -> Int? {
        return productImageStatuses.firstIndex(where: { status -> Bool in
            switch status {
            case .uploading(let uploadingAsset, let siteID, let productID):
                return uploadingAsset == asset && siteID == self.siteID && productID == self.productOrVariationID
            case .uploadFailure(let failedAsset, _, let siteID, let productID):
                return failedAsset == asset && siteID == self.siteID && productID == self.productOrVariationID
            case .remote:
                return false
            }
        })
    }

    func updateProductImageStatus(at index: Int, productImage: ProductImage) {
        if case .uploading(let asset, _, _) = productImageStatuses[safe: index] {
            observations.assetUploaded.values.forEach { closure in
                closure(asset, .success(productImage))
            }
        }

        productImageStatuses[index] = .remote(image: productImage, siteID: siteID, productID: productOrVariationID)
    }

    func updateProductImageStatus(at index: Int, error: Error) {
        if case .uploading(let asset, let siteID, let productID) = productImageStatuses[safe: index] {
            observations.assetUploaded.values.forEach { closure in
                closure(asset, .failure(error))
            }
            productImageStatuses[index] = .uploadFailure(asset: asset, error: error, siteID: siteID, productID: productID)
        } else {
            productImageStatuses.remove(at: index)
        }
    }
}
