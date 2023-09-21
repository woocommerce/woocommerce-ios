import Foundation
import Yosemite

/// View model for `AddProductFeaturesView`.
///
final class AddProductFeaturesViewModel: ObservableObject {

    /// Closure fired when tapping "Set tone and voice" to launch the AI tone sheet
    ///
    let onSetToneAndVoice: () -> Void

    @Published var productFeatures: String = ""
    let productName: String

    private let siteID: Int64
    private let stores: StoresManager
    private let analytics: Analytics
    // TODO: add new type for product details and return it here.
    private let onProductDetailsCreated: () -> Void


    init(siteID: Int64,
         productName: String,
         stores: StoresManager = ServiceLocator.stores,
         analytics: Analytics = ServiceLocator.analytics,
         onSetToneAndVoice: @escaping () -> Void,
         onProductDetailsCreated: @escaping () -> Void) {
        self.siteID = siteID
        self.productName = productName
        self.stores = stores
        self.analytics = analytics
        self.onSetToneAndVoice = onSetToneAndVoice
        self.onProductDetailsCreated = onProductDetailsCreated
    }
}
