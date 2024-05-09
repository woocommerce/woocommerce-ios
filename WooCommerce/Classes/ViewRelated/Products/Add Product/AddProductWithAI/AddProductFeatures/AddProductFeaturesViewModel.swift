import Foundation
import Yosemite
import protocol WooFoundation.Analytics

/// View model for `AddProductFeaturesView`.
///
final class AddProductFeaturesViewModel: ObservableObject {
    let siteID: Int64
    let productName: String

    @Published var productFeatures: String

    private let stores: StoresManager
    private let analytics: Analytics
    // TODO: add new type for product details and return it here.
    private let onCompletion: (String) -> Void

    init(siteID: Int64,
         productName: String,
         productFeatures: String? = nil,
         stores: StoresManager = ServiceLocator.stores,
         analytics: Analytics = ServiceLocator.analytics,
         onCompletion: @escaping (String) -> Void) {
        self.siteID = siteID
        self.productName = productName
        self.productFeatures = productFeatures ?? ""
        self.stores = stores
        self.analytics = analytics
        self.onCompletion = onCompletion
    }

    func proceedToPreview() {
        onCompletion(productFeatures)
    }
}
