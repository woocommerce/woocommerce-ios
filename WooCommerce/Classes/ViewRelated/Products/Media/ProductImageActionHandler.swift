import Photos
import Yosemite

/// Encapsulates the implementation of Product images actions from the UI.
///
final class ProductImageActionHandler {
    typealias OnAllStatusesUpdate = ([ProductImageStatus], Error?) -> Void
    typealias OnAssetUpload = (PHAsset, ProductImage) -> Void

    private let siteID: Int64

    private(set) var productImageStatuses: [ProductImageStatus] {
        didSet {
            observations.allStatusesUpdated.values.forEach { closure in
                closure(productImageStatuses, nil)
            }
        }
    }

    private var observations = (
        allStatusesUpdated: [UUID: OnAllStatusesUpdate](),
        assetUploaded: [UUID: OnAssetUpload]()
    )

    init(siteID: Int64, product: Product) {
        self.siteID = siteID
        self.productImageStatuses = product.imageStatuses
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

        observations.allStatusesUpdated[id] = { [weak self, weak observer] statuses, error in
            // If the observer has been deallocated, we can
            // automatically remove the observation closure.
            guard observer != nil else {
                self?.observations.allStatusesUpdated.removeValue(forKey: id)
                return
            }

            onUpdate(statuses, error)
        }

        // Sends the initial value.
        onUpdate(productImageStatuses, nil)

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
        productImageStatuses = newProductImageStatuses + productImageStatuses
    }

    func uploadMediaAssetToSiteMediaLibrary(asset: PHAsset) {
        productImageStatuses = [.uploading(asset: asset)] + productImageStatuses

        let action = MediaAction.uploadMedia(siteID: siteID,
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
        productImageStatuses.removeAll { status -> Bool in
            guard case .remote(let image) = status else {
                return false
            }
            return image.imageID == productImage.imageID
        }
    }
}

private extension ProductImageActionHandler {
    func index(of asset: PHAsset) -> Int? {
        return productImageStatuses.firstIndex(where: { status -> Bool in
            switch status {
            case .uploading(let uploadingAsset):
                return uploadingAsset == asset
            default:
                return false
            }
        })
    }

    func updateProductImageStatus(at index: Int, productImage: ProductImage) {
        if case .uploading(let asset) = productImageStatuses[safe: index] {
            observations.assetUploaded.values.forEach { closure in
                closure(asset, productImage)
            }
        }

        productImageStatuses[index] = .remote(image: productImage)
    }

    func updateProductImageStatus(at index: Int, error: Error?) {
        productImageStatuses.remove(at: index)
    }
}
