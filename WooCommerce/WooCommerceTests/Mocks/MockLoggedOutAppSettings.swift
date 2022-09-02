@testable import WooCommerce

final class MockLoggedOutAppSettings: LoggedOutAppSettingsProtocol {
    var hasFinishedOnboarding: Bool
    var errorLoginSiteAddress: String?

    init(hasFinishedOnboarding: Bool = false,
         errorLoginSiteAddress: String? = nil) {
        self.hasFinishedOnboarding = hasFinishedOnboarding
        self.errorLoginSiteAddress = errorLoginSiteAddress
    }

    func setHasFinishedOnboarding(_ hasFinishedOnboarding: Bool) {
        self.hasFinishedOnboarding = hasFinishedOnboarding
    }

    func setErrorLoginSiteAddress(_ address: String?) {
        self.errorLoginSiteAddress = address
    }
}
