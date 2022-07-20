@testable import WooCommerce

final class MockLoggedOutAppSettings: LoggedOutAppSettingsProtocol {
    var hasFinishedOnboarding: Bool

    init(hasFinishedOnboarding: Bool = false) {
        self.hasFinishedOnboarding = hasFinishedOnboarding
    }

    func setHasFinishedOnboarding(_ hasFinishedOnboarding: Bool) {
        self.hasFinishedOnboarding = hasFinishedOnboarding
    }
}
