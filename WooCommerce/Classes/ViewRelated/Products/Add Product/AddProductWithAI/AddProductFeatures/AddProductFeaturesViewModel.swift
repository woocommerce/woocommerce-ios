import Foundation
import Yosemite

/// View model for `AddProductFeaturesView`.
///
final class AddProductFeaturesViewModel: ObservableObject {
    let siteID: Int64
    let productName: String

    @Published var productFeatures: String = ""

    private let stores: StoresManager
    private let analytics: Analytics
    // TODO: add new type for product details and return it here.
    private let onProductDetailsCreated: () -> Void

    init(siteID: Int64,
         productName: String,
         stores: StoresManager = ServiceLocator.stores,
         analytics: Analytics = ServiceLocator.analytics,
         onProductDetailsCreated: @escaping () -> Void) {
        self.siteID = siteID
        self.productName = productName
        self.stores = stores
        self.analytics = analytics
        self.onProductDetailsCreated = onProductDetailsCreated
    }
}
