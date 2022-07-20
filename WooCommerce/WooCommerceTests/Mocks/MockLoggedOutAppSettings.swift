@testable import WooCommerce

final class MockLoggedOutAppSettings: LoggedOutAppSettings {
    var hasInteractedWithOnboarding: Bool

    init(hasInteractedWithOnboarding: Bool = false) {
        self.hasInteractedWithOnboarding = hasInteractedWithOnboarding
    }

    func setHasInteractedWithOnboarding(_ hasInteractedWithOnboarding: Bool) {
        self.hasInteractedWithOnboarding = hasInteractedWithOnboarding
    }
}
