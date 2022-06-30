import Combine
import Yosemite

final class ProductImagesSaver {
    /// Initially set when product save is requested when all images at the time of request are uploaded.
    /// As each pending image is uploaded, the statuses are also updated and ready to save when none is pending upload.
    private(set) var imageStatusesToSave: [ProductImageStatus] = [] {
        didSet {
            imageStatusesToSaveSubject.send(imageStatusesToSave)
        }
    }
    // The use of a `PassthroughSubject` sent on variable `didSet` instead of a `@Published` is because `@Published`
    // subscription happens in `willSet` while we want to update the statuses after `didSet`.
    private let imageStatusesToSaveSubject: PassthroughSubject<[ProductImageStatus], Never> = .init()

    private var uploadStatusesSubscription: AnyCancellable?
    private var assetUploadSubscription: AnyCancellable?

    private let siteID: Int64
    private let productOrVariationID: ProductOrVariationID
    private let stores: StoresManager

    init(siteID: Int64, productOrVariationID: ProductOrVariationID, stores: StoresManager = ServiceLocator.stores) {
        self.siteID = siteID
        self.productOrVariationID = productOrVariationID
        self.stores = stores
    }

    /// If any images are pending upload, saves the product remotely with the uploaded images when none is pending upload.
    /// - Parameters:
    ///   - imageActionHandler: action handler that provides the latest image statuses and image asset upload subscription.
    ///   - onProductSave: called after the product is updated remotely with the uploaded images.
    func saveProductImagesWhenNoneIsPendingUploadAnymore(imageActionHandler: ProductImageActionHandler,
                                                         onProductSave: @escaping (Result<[ProductImage], Error>) -> Void) {
        let imageStatuses = imageActionHandler.productImageStatuses
        guard imageStatuses.hasPendingUpload else {
            return
        }

        imageStatusesToSave = imageStatuses

        observeImageStatusesToSaveProductRemotelyWhenNoneIsPendingUploadAnymore(onProductSave: onProductSave)
        observeAssetUploadsToUpdateImageStatuses(imageActionHandler: imageActionHandler)
    }
}

private extension ProductImagesSaver {
    func observeImageStatusesToSaveProductRemotelyWhenNoneIsPendingUploadAnymore(
        onProductSave: @escaping (Result<[ProductImage], Error>) -> Void
    ) {
        uploadStatusesSubscription = imageStatusesToSaveSubject
            .filter { $0.hasPendingUpload == false }
            .map { $0.images }
            .filter { $0.isNotEmpty }
            .sink(receiveValue: { [weak self] images in
                self?.saveProductImages(images, onProductSave: onProductSave)
            })
    }

    func saveProductImages(_ images: [ProductImage], onProductSave: @escaping (Result<[ProductImage], Error>) -> Void) {
        switch productOrVariationID {
        case .product(let productID):
            let action = ProductAction.updateProductImages(siteID: siteID,
                                                           productID: productID,
                                                           images: images) { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success(let product):
                    onProductSave(.success(product.images))
                case .failure(let error):
                    onProductSave(.failure(error))
                }
                self.imageStatusesToSave = []
                self.assetUploadSubscription = nil
                self.uploadStatusesSubscription = nil
            }
            stores.dispatch(action)
        case .variation(_, _):
            // TODO: 7021 - update variation images action with a different endpoint
            return
        }
    }

    func observeAssetUploadsToUpdateImageStatuses(imageActionHandler: ProductImageActionHandler) {
        assetUploadSubscription = imageActionHandler.addAssetUploadObserver(self) { [weak self] asset, result in
            guard let self = self else { return }
            guard let index = self.imageStatusesToSave.firstIndex(where: { status -> Bool in
                switch status {
                case .uploading(let uploadingAsset):
                    return uploadingAsset == asset
                default:
                    return false
                }
            }) else {
                return
            }

            switch result {
            case .success(let productImage):
                self.updateProductImageStatus(at: index, productImage: productImage)
            case .failure(let error):
                self.updateProductImageStatus(at: index, error: error)
            }
        }
    }

    func updateProductImageStatus(at index: Int, productImage: ProductImage) {
        imageStatusesToSave[index] = .remote(image: productImage)
    }

    func updateProductImageStatus(at index: Int, error: Error?) {
        imageStatusesToSave.remove(at: index)
    }
}
