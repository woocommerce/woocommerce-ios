import Combine
import Photos
import Yosemite

/// Interface of `ProductImageActionHandler` to allow mocking in unit tests.
protocol ProductImageActionHandlerProtocol {
    typealias AllStatuses = (productImageStatuses: [ProductImageStatus], error: Error?)
    typealias OnAllStatusesUpdate = (AllStatuses) -> Void
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
}

/// Encapsulates the implementation of Product images actions from the UI.
///
final class ProductImageActionHandler: ProductImageActionHandlerProtocol {
    typealias AllStatuses = (productImageStatuses: [ProductImageStatus], error: Error?)
    typealias OnAllStatusesUpdate = (AllStatuses) -> Void
    typealias OnAssetUpload = (ProductImageAssetType, Result<ProductImage, Error>) -> Void

    private let siteID: Int64
    private var productOrVariationID: ProductOrVariationID

    /// The queue where internal states like `allStatuses` and `observations` are updated on to maintain thread safety.
    private let queue: DispatchQueue

    private let stores: StoresManager

    var productImageStatuses: [ProductImageStatus] {
        return allStatuses.productImageStatuses
    }

    private var allStatuses: AllStatuses {
        didSet {
            queue.async { [weak self] in
                guard let self = self else {
                    return
                }
                self.observations.allStatusesUpdated.values.forEach { closure in
                    closure(self.allStatuses)
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
        self.allStatuses = (productImageStatuses: imageStatuses, error: nil)
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
            guard let self = self else {
                return
            }

            self.observations.allStatusesUpdated[id] = { [weak self, weak observer] allStatuses in
                guard let self = self else {
                    return
                }

                // If the observer has been deallocated, we can
                // automatically remove the observation closure.
                guard observer != nil else {
                    self.observations.allStatusesUpdated.removeValue(forKey: id)
                    return
                }

                onUpdate(self.allStatuses)
            }

            // Sends the initial value.
            onUpdate(self.allStatuses)
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
            guard let self = self else {
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
            guard let self = self else {
                return
            }

            let newProductImageStatuses = mediaItems.map { ProductImageStatus.remote(image: $0.toProductImage) }
            let imageStatuses = newProductImageStatuses + self.productImageStatuses
            self.allStatuses = (productImageStatuses: imageStatuses, error: nil)
        }
    }

    func uploadMediaAssetToSiteMediaLibrary(asset: ProductImageAssetType) {
        queue.async { [weak self] in
            guard let self = self else {
                return
            }

            let imageStatuses = [.uploading(asset: asset)] + self.allStatuses.productImageStatuses
            self.allStatuses = (productImageStatuses: imageStatuses, error: nil)

            self.uploadMediaAssetToSiteMediaLibrary(asset: asset) { [weak self] result in
                                                self?.queue.async { [weak self] in
                                                    guard let self = self else {
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
            guard let self = self else { return }
            let action: MediaAction
            switch asset {
                case .phAsset(let asset):
                    action = MediaAction.uploadMedia(siteID: self.siteID, productID: self.productOrVariationID.id, mediaAsset: asset, onCompletion: onCompletion)
                case .uiImage(let image):
                    action = MediaAction.uploadMedia(siteID: self.siteID, productID: self.productOrVariationID.id, mediaAsset: image, onCompletion: onCompletion)
            }
            self.stores.dispatch(action)
        }
    }

    /// Updates the `productID` with the provided `remoteProductID`
    ///
    /// Used for updating the product ID during create product flow. i.e. To replace the local product ID with the remote product ID.
    ///
    func updateProductID(_ remoteProductID: ProductOrVariationID) {
        self.productOrVariationID = remoteProductID
    }

    func deleteProductImage(_ productImage: ProductImage) {
        queue.async { [weak self] in
            guard let self = self else {
                return
            }

            var imageStatuses = self.allStatuses.productImageStatuses
            imageStatuses.removeAll { status -> Bool in
                guard case .remote(let image) = status else {
                    return false
                }
                return image.imageID == productImage.imageID
            }
            self.allStatuses = (productImageStatuses: imageStatuses, error: nil)
        }
    }

    /// Resets the product images to the ones from the given Product.
    ///
    func resetProductImages(to product: ProductFormDataModel) {
        queue.async { [weak self] in
            guard let self = self else {
                return
            }

            self.allStatuses = (productImageStatuses: product.imageStatuses, error: nil)
        }
    }

    /// Updates the product images with the given ones.
    ///
    func updateProductImageStatusesAfterReordering(_ productImageStatuses: [ProductImageStatus]) {
        queue.async { [weak self] in
            guard let self = self else {
                return
            }

            self.allStatuses = (productImageStatuses: productImageStatuses, error: nil)
        }
    }
}

private extension ProductImageActionHandler {
    func index(of asset: ProductImageAssetType) -> Int? {
        return allStatuses.productImageStatuses.firstIndex(where: { status -> Bool in
            switch status {
            case .uploading(let uploadingAsset):
                return uploadingAsset == asset
            default:
                return false
            }
        })
    }

    func updateProductImageStatus(at index: Int, productImage: ProductImage) {
        if case .uploading(let asset) = allStatuses.productImageStatuses[safe: index] {
            observations.assetUploaded.values.forEach { closure in
                closure(asset, .success(productImage))
            }
        }

        var imageStatuses = allStatuses.productImageStatuses
        imageStatuses[index] = .remote(image: productImage)
        allStatuses = (productImageStatuses: imageStatuses, error: nil)
    }

    func updateProductImageStatus(at index: Int, error: Error) {
        if case .uploading(let asset) = allStatuses.productImageStatuses[safe: index] {
            observations.assetUploaded.values.forEach { closure in
                closure(asset, .failure(error))
            }
        }

        var imageStatuses = allStatuses.productImageStatuses
        imageStatuses.remove(at: index)
        allStatuses = (productImageStatuses: imageStatuses, error: error)
    }
}
