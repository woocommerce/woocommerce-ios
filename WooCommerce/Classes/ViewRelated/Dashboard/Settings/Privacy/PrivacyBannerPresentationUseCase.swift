import Foundation
import Yosemite
import CoreTelephony

/// Type who informs us if the privacy banner should be shown or not.
///
final class PrivacyBannerPresentationUseCase {

    /// User Defaults database
    ///
    private let defaults: UserDefaults

    /// Stores to fetch remote information.
    ///
    private let stores: StoresManager

    /// Users current locale.
    ///
    private let currentLocale: Locale

    init(defaults: UserDefaults = UserDefaults.standard, stores: StoresManager = ServiceLocator.stores, currentLocale: Locale = .autoupdatingCurrent) {
        self.defaults = defaults
        self.stores = stores
        self.currentLocale = currentLocale
    }

    /// Returns `true` if the privacy banner should be shown.
    /// Currently it is shown if the user is in the EU zone & privacy choices have not been saved.
    ///
    func shouldShowPrivacyBanner() async -> Bool {
        // Early exit if privacy settings have been saved to prevent unnecessary API calls.
        guard !defaults.hasSavedPrivacyBannerSettings else {
            return false
        }

        do {
            let countryCode = try await fetchUsersCountryCode()
            let isCountryInEU = Country.GDPRCountryCodes.contains(countryCode)
            return isCountryInEU
        } catch {
            DDLogInfo("⛔️ Could not determine users country code. Error: \(error)")
            return false
        }
    }
}

// MARK: Private Helpers
private extension PrivacyBannerPresentationUseCase {

    /// Determines the user country. Relies on the public WordPress API.
    ///
    func fetchUsersCountryCode() async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            let action = UserAction.fetchUserIPCountryCode { result in
                continuation.resume(with: result)
            }
            Task { @MainActor in
                stores.dispatch(action)
            }
        }
    }
}

private extension UserDefaults {
    @objc dynamic var hasSavedPrivacyBannerSettings: Bool {
        bool(forKey: Key.hasSavedPrivacyBannerSettings.rawValue)
    }
}
