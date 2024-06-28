import Foundation
import protocol WooFoundation.Analytics

/// View model for `ProductCreationAIStartingInfoView`.
///
final class ProductCreationAIStartingInfoViewModel: ObservableObject {
    @Published var features: String

    let siteID: Int64
    private let analytics: Analytics

    var productFeatures: String? {
        guard features.isNotEmpty else {
            return nil
        }
        return features
    }

    init(siteID: Int64, analytics: Analytics = ServiceLocator.analytics) {
        self.siteID = siteID
        self.features = ""
        self.analytics = analytics
    }

    func didTapReadTextFromPhoto() {
        // TODO: 13103 - Add tracking
    }

    func didTapContinue() {
        // TODO: 13103 - Add tracking
    }
}
