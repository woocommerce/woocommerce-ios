import Photos
import Yosemite

/// Encapsulates the implementation of Product images actions from the UI.
///
final class ProductImageActionHandler {
    typealias AllStatuses = (productImageStatuses: [ProductImageStatus], error: Error?)
    typealias OnAllStatusesUpdate = (AllStatuses) -> Void
    typealias OnAssetUpload = (PHAsset, ProductImage) -> Void

    private let siteID: Int64
    private let productID: Int64

    var productImageStatuses: [ProductImageStatus] {
        return allStatuses.productImageStatuses
    }

    private var allStatuses: AllStatuses {
        didSet {
            observations.allStatusesUpdated.values.forEach { closure in
                closure(allStatuses)
            }
        }
    }

    private var observations = (
        allStatusesUpdated: [UUID: OnAllStatusesUpdate](),
        assetUploaded: [UUID: OnAssetUpload]()
    )

    init(siteID: Int64, product: Product) {
        self.siteID = siteID
        self.productID = product.productID
        self.allStatuses = (productImageStatuses: product.imageStatuses, error: nil)
    }

    /// Observes when the image statuses have been updated.
    ///
    /// - Parameters:
    ///   - observer: the observer that `onUpdate` is associated with.
    ///   - onUpdate: called when the image statuses have been updated, if `observer` is not nil.
    @discardableResult
    func addUpdateObserver<T: AnyObject>(_ observer: T,
                                         onUpdate: @escaping OnAllStatusesUpdate) -> ObservationToken {
        let id = UUID()

        observations.allStatusesUpdated[id] = { [weak self, weak observer] allStatuses in
            // If the observer has been deallocated, we can
            // automatically remove the observation closure.
            guard observer != nil else {
                self?.observations.allStatusesUpdated.removeValue(forKey: id)
                return
            }

            onUpdate(allStatuses)
        }

        // Sends the initial value.
        onUpdate(allStatuses)

        return ObservationToken { [weak self] in
            self?.observations.allStatusesUpdated.removeValue(forKey: id)
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

        observations.assetUploaded[id] = { [weak self, weak observer] asset, productImage in
            // If the observer has been deallocated, we can
            // automatically remove the observation closure.
            guard observer != nil else {
                self?.observations.assetUploaded.removeValue(forKey: id)
                return
            }

            onAssetUpload(asset, productImage)
        }

        return ObservationToken { [weak self] in
            self?.observations.assetUploaded.removeValue(forKey: id)
        }
    }

    func addSiteMediaLibraryImagesToProduct(mediaItems: [Media]) {
        let newProductImageStatuses = mediaItems.map { ProductImageStatus.remote(image: $0.toProductImage) }
        let imageStatuses = newProductImageStatuses + productImageStatuses
        allStatuses = (productImageStatuses: imageStatuses, error: nil)
    }

    func uploadMediaAssetToSiteMediaLibrary(asset: PHAsset) {
        let imageStatuses = [.uploading(asset: asset)] + allStatuses.productImageStatuses
        allStatuses = (productImageStatuses: imageStatuses, error: nil)

        let action = MediaAction.uploadMedia(siteID: siteID,
                                             productID: productID,
                                             mediaAsset: asset) { [weak self] (media, error) in
                                                guard let self = self else {
                                                    return
                                                }

                                                guard let index = self.index(of: asset) else {
                                                    return
                                                }

                                                guard let media = media else {
                                                    DispatchQueue.main.async {
                                                        self.updateProductImageStatus(at: index, error: error)
                                                    }
                                                    return
                                                }
                                                let productImage = ProductImage(imageID: media.mediaID,
                                                                                dateCreated: media.date,
                                                                                dateModified: media.date,
                                                                                src: media.src,
                                                                                name: media.name,
                                                                                alt: media.alt)
                                                DispatchQueue.main.async {
                                                    self.updateProductImageStatus(at: index, productImage: productImage)
                                                }
        }
        ServiceLocator.stores.dispatch(action)
    }

    func deleteProductImage(_ productImage: ProductImage) {
        var imageStatuses = allStatuses.productImageStatuses
        imageStatuses.removeAll { status -> Bool in
            guard case .remote(let image) = status else {
                return false
            }
            return image.imageID == productImage.imageID
        }
        allStatuses = (productImageStatuses: imageStatuses, error: nil)
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
