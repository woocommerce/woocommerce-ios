import Photos
import Yosemite

/// Encapsulates the implementation of Product images actions from the UI.
///
final class ProductImagesService {
    typealias OnUpdate = ([ProductImageStatus], Error?) -> Void

    private let siteID: Int64
    private let productImagesProvider: ProductImagesProvider

    private(set) var productImageStatuses: [ProductImageStatus] {
        didSet {
            observations.values.forEach { closure in
                closure(productImageStatuses, nil)
            }
        }
    }

    private var observations = [UUID: OnUpdate]()

    init(siteID: Int64, product: Product, productImagesProvider: ProductImagesProvider) {
        self.siteID = siteID
        self.productImageStatuses = product.imageStatuses
        self.productImagesProvider = productImagesProvider
    }

    @discardableResult
    func addUpdateObserver<T: AnyObject>(_ observer: T,
                                         onUpdate: @escaping OnUpdate) -> ObservationToken {
        let id = UUID()

        observations[id] = { [weak self, weak observer] statuses, error in
            // If the observer has been deallocated, we can
            // automatically remove the observation closure.
            guard observer != nil else {
                self?.observations.removeValue(forKey: id)
                return
            }

            onUpdate(statuses, error)
        }

        // Sends the initial value.
        onUpdate(productImageStatuses, nil)

        return ObservationToken { [weak self] in
            self?.observations.removeValue(forKey: id)
        }
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

private extension ProductImagesService {
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
        if case .uploading(let asset) = productImageStatuses[index] {
            productImagesProvider.update(from: asset, to: productImage)
        }

        productImageStatuses[index] = .remote(image: productImage)
    }

    func updateProductImageStatus(at index: Int, error: Error?) {
        productImageStatuses.remove(at: index)
    }
}
