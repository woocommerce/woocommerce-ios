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

    /// Determines the user country code by the following algorithm.
    /// - If the user has a WPCOM account:
    ///   - Use the ip country code.
    /// - If the user does not has a WPCOM account:
    ///   - Use a 3rd party ip country code or current locale country code upon failure.
    ///
    func fetchUsersCountryCode() async throws -> String {
        // Use ip country code for WPCom accounts
        if !stores.isAuthenticatedWithoutWPCom {
            return try await fetchWPCOMIPCountryCode()
        }

        // Use 3rd party ip-country code or locale as a fallback.
        do {
            return try await fetch3rdPartyIPCountryCode()
        } catch {
            return fetchLocaleCountryCode()
        }
    }

    /// Fetches the ip country code using the Account API.
    ///
    func fetchWPCOMIPCountryCode() async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            let action = AccountAction.synchronizeAccount { result in
                let ipCountryCodeResult = result.map { $0.ipCountryCode }
                continuation.resume(with: ipCountryCodeResult)
            }
            Task { @MainActor in
                stores.dispatch(action)
            }
        }
    }

    /// Fetches the ip country code using a 3rd party API.
    ///
    func fetch3rdPartyIPCountryCode() async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            let action = UserAction.fetchUserIPCountryCode { result in
                continuation.resume(with: result)
            }
            Task { @MainActor in
                stores.dispatch(action)
            }
        }
    }

    /// Fetches the country code from the current locate.
    ///
    func fetchLocaleCountryCode() -> String {
        currentLocale.regionCode ?? ""
    }
}

private extension UserDefaults {
    @objc dynamic var hasSavedPrivacyBannerSettings: Bool {
        bool(forKey: Key.hasSavedPrivacyBannerSettings.rawValue)
    }
}
