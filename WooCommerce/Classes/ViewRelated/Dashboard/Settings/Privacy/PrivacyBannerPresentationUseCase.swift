import Foundation

/// Type who informs us if the privacy banner should be shown or not.
///
struct PrivacyBannerPresentationUseCase {

    /// Users current location country code.
    ///
    private let countryCode: String

    /// User Defaults database
    ///
    private let defaults: UserDefaults

    init(countryCode: String, defaults: UserDefaults = UserDefaults.standard) {
        self.countryCode = countryCode
        self.defaults = defaults
    }

    /// Returns `true` if the privacy banner should be shown.
    /// Currently it is shown if the user is in the EU zone & privacy choices have not been saved.
    ///
    func shouldShowPrivacyBanner() -> Bool {
        // TODO: Implement
        return true
    }
}
