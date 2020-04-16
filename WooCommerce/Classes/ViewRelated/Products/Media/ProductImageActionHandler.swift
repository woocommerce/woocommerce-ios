import Photos
import Yosemite

/// Encapsulates the implementation of Product images actions from the UI.
///
final class ProductImageActionHandler {
    typealias AllStatuses = (productImageStatuses: [ProductImageStatus], error: Error?)
    typealias OnAllStatusesUpdate = (AllStatuses) -> Void
    typealias OnAssetUpload = (PHAsset, ProductImage) -> Void

    private let siteID: Int64

    /// The queue where internal states like `allStatuses` and `observations` are updated on to maintain thread safety.
    private let queue: DispatchQueue

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
    ///   - product: the product whose image statuses and actions are of concern.
    ///   - queue: the queue where the update callbacks are called on. Default to be the main queue.
    init(siteID: Int64, product: Product, queue: DispatchQueue = .main) {
        self.siteID = siteID
        self.queue = queue
        self.allStatuses = (productImageStatuses: product.imageStatuses, error: nil)
    }

    /// Observes when the image statuses have been updated.
    ///
    /// - Parameters:
    ///   - observer: the observer that `onUpdate` is associated with.
    ///   - onUpdate: called when the image statuses have been updated on the thread passed in the initializer (default to the main thread),
    ///               if `observer` is not nil.
    @discardableResult
    func addUpdateObserver<T: AnyObject>(_ observer: T,
                                         onUpdate: @escaping OnAllStatusesUpdate) -> ObservationToken {
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

        return ObservationToken { [weak self] in
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
    @discardableResult
    func addAssetUploadObserver<T: AnyObject>(_ observer: T,
                                              onAssetUpload: @escaping OnAssetUpload) -> ObservationToken {
        let id = UUID()

        queue.async { [weak self] in
            guard let self = self else {
                return
            }

            self.observations.assetUploaded[id] = { [weak self, weak observer] asset, productImage in
                // If the observer has been deallocated, we can
                // automatically remove the observation closure.
                guard observer != nil else {
                    self?.observations.assetUploaded.removeValue(forKey: id)
                    return
                }

                onAssetUpload(asset, productImage)
            }
        }

        return ObservationToken { [weak self] in
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

    func uploadMediaAssetToSiteMediaLibrary(asset: PHAsset) {
        queue.async { [weak self] in
            guard let self = self else {
                return
            }

            let imageStatuses = [.uploading(asset: asset)] + self.allStatuses.productImageStatuses
            self.allStatuses = (productImageStatuses: imageStatuses, error: nil)

            self.uploadMediaAssetToSiteMediaLibrary(asset: asset) { [weak self] (media, error) in
                                                self?.queue.async { [weak self] in
                                                    guard let self = self else {
                                                        return
                                                    }

                                                    guard let index = self.index(of: asset) else {
                                                        return
                                                    }

                                                    guard let media = media else {
                                                        self.updateProductImageStatus(at: index, error: error)
                                                        return
                                                    }
                                                    let productImage = ProductImage(imageID: media.mediaID,
                                                                                    dateCreated: media.date,
                                                                                    dateModified: media.date,
                                                                                    src: media.src,
                                                                                    name: media.name,
                                                                                    alt: media.alt)
                                                    self.updateProductImageStatus(at: index, productImage: productImage)
                                                }
            }
        }
    }

    private func uploadMediaAssetToSiteMediaLibrary(asset: PHAsset, onCompletion: @escaping (_ uploadedMedia: Media?, _ error: Error?) -> Void) {
        DispatchQueue.main.async { [weak self] in
            guard let siteID = self?.siteID else {
                return
            }

            let action = MediaAction.uploadMedia(siteID: siteID, mediaAsset: asset, onCompletion: onCompletion)
            ServiceLocator.stores.dispatch(action)
        }
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
    func resetProductImages(to product: Product) {
        allStatuses = (productImageStatuses: product.imageStatuses, error: nil)
    }
}

private extension ProductImageActionHandler {
    func index(of asset: PHAsset) -> Int? {
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
                closure(asset, productImage)
            }
        }

        var imageStatuses = allStatuses.productImageStatuses
        imageStatuses[index] = .remote(image: productImage)
        allStatuses = (productImageStatuses: imageStatuses, error: nil)
    }

    func updateProductImageStatus(at index: Int, error: Error?) {
        var imageStatuses = allStatuses.productImageStatuses
        imageStatuses.remove(at: index)
        allStatuses = (productImageStatuses: imageStatuses, error: error)
    }
}
