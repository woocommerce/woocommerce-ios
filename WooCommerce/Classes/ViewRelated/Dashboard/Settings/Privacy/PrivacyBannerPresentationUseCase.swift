import Foundation
import Yosemite

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
        let isCountryInEU = Country.EUCountryCodes.contains(countryCode)
        let hasSavedPrivacySettings = defaults.hasSavedPrivacyBannerSettings
        return isCountryInEU && !hasSavedPrivacySettings
    }
}

private extension UserDefaults {
    @objc dynamic var hasSavedPrivacyBannerSettings: Bool {
        bool(forKey: Key.hasSavedPrivacyBannerSettings.rawValue)
    }
}
