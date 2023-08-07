import Foundation
import Yosemite

/// View model for `StoreCreationProfilerQuestionContainer`.
final class StoreCreationProfilerQuestionContainerViewModel: ObservableObject {

    private let storeName: String
    private let analytics: Analytics
    private let completionHandler: (SiteProfilerData?) -> Void

    private var storeCategory: StoreCreationCategoryAnswer?
    private var sellingStatus: StoreCreationSellingStatusAnswer?
    private var storeCountry: SiteAddress.CountryCode = .US

    init(storeName: String,
         analytics: Analytics = ServiceLocator.analytics,
         onCompletion: @escaping (SiteProfilerData?) -> Void) {
        self.storeName = storeName
        self.analytics = analytics
        self.completionHandler = onCompletion
    }
}
