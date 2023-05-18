import Foundation
import Yosemite

/// ViewModel for the privacy banner
///
final class PrivacyBannerViewModel: ObservableObject {

    /// Stores the value for the analytics choice.
    ///
    @Published var analyticsEnabled: Bool = false

    init(analytics: Analytics = ServiceLocator.analytics) {
        self.analyticsEnabled = analytics.userHasOptedIn
    }
}
