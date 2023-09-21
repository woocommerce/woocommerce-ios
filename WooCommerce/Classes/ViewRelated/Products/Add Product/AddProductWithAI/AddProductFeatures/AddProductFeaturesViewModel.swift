import Foundation
import Yosemite

/// View model for `AddProductFeaturesView`.
///
final class AddProductFeaturesViewModel: ObservableObject {

    @Published var productFeatures: String = ""
    let productName: String

    private let siteID: Int64
    private let stores: StoresManager
    private let analytics: Analytics
    // TODO: add new type for product details and return it here.
    private let onCompletion: (String) -> Void

    init(siteID: Int64,
         productName: String,
         stores: StoresManager = ServiceLocator.stores,
         analytics: Analytics = ServiceLocator.analytics,
         onCompletion: @escaping (String) -> Void) {
        self.siteID = siteID
        self.productName = productName
        self.stores = stores
        self.analytics = analytics
        self.onCompletion = onCompletion
    }

    func proceedToPreview() {
        // TODO: analytics
        onCompletion(productFeatures)
    }
}
