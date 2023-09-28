import Foundation
import Yosemite

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
    @Binding private var isFirstAttemptGeneratingDetails: Bool

    init(siteID: Int64,
         isFirstAttemptGeneratingDetails: Binding<Bool>,
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
        self._isFirstAttemptGeneratingDetails = isFirstAttemptGeneratingDetails
    }

    func proceedToPreview() {
        analytics.track(event: .ProductCreationAI.generateDetailsTapped(isFirstAttempt: isFirstAttemptGeneratingDetails))
        onCompletion(productFeatures)
    }
}
