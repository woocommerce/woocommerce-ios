import Combine
import Photos
@testable import WooCommerce
import struct Yosemite.Media
import struct Yosemite.ProductImage

final class MockProductImageActionHandler: ProductImageActionHandlerProtocol {
    typealias AllStatuses = (productImageStatuses: [ProductImageStatus], error: Error?)
    typealias OnAssetUpload = (ProductImageAssetType, Result<ProductImage, Error>) -> Void

    var productImageStatuses: [ProductImageStatus] {
        allStatuses.productImageStatuses
    }

    // Can be set externally to be emitted in `addUpdateObserver`.
    @Published var allStatuses: AllStatuses

    // Can be set externally to be emitted in `addAssetUploadObserver`.
    @Published var assetUploadResults: (asset: ProductImageAssetType, result: Result<ProductImage, Error>)?

    init(productImageStatuses: [ProductImageStatus]) {
        self.allStatuses = (productImageStatuses: productImageStatuses, error: nil)
    }

    func addUpdateObserver<T>(_ observer: T, onUpdate: @escaping OnAllStatusesUpdate) -> AnyCancellable where T: AnyObject {
        return $allStatuses.sink { statuses in
            onUpdate(statuses)
        }
    }

    func addAssetUploadObserver<T>(_ observer: T, onAssetUpload: @escaping OnAssetUpload) -> AnyCancellable where T: AnyObject {
        return $assetUploadResults
            .compactMap { $0 }
            .sink { result in
                onAssetUpload(result.asset, result.result)
            }
    }

    func addSiteMediaLibraryImagesToProduct(mediaItems: [Media]) {
        // no-op
    }

    func uploadMediaAssetToSiteMediaLibrary(asset: ProductImageAssetType) {
        // no-op
    }

    func updateProductID(_ remoteProductID: ProductOrVariationID) {
        // no-op
    }

    func deleteProductImage(_ productImage: ProductImage) {
        // no-op
    }

    func resetProductImages(to product: ProductFormDataModel) {
        // no-op
    }

    func updateProductImageStatusesAfterReordering(_ productImageStatuses: [ProductImageStatus]) {
        // no-op
    }
}
