/// Used for `ServiceLocator.productImageUploader` if `backgroundProductImageUpload` feature flag is off.
final class LegacyProductImageUploader: ProductImageUploaderProtocol {
    func actionHandler(siteID: Int64, productID: Int64, isLocalID: Bool, originalStatuses: [ProductImageStatus]) -> ProductImageActionHandler {
        ProductImageActionHandler(siteID: siteID, productID: productID, imageStatuses: originalStatuses)
    }
}
