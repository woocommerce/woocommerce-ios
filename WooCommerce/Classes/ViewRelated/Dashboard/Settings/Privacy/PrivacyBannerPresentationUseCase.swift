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

    init(defaults: UserDefaults = UserDefaults.standard, stores: StoresManager = ServiceLocator.stores) {
        self.defaults = defaults
        self.stores = stores
    }

    /// Returns `true` if the privacy banner should be shown.
    /// Currently it is shown if the user is in the EU zone & privacy choices have not been saved.
    ///
    func shouldShowPrivacyBanner() async -> Bool {
        do {
            let countryCode = try await fetchUsersCountryCode()
            let isCountryInEU = Country.GDPRCountryCodes.contains(countryCode)
            let hasSavedPrivacySettings = defaults.hasSavedPrivacyBannerSettings
            return isCountryInEU && !hasSavedPrivacySettings
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
    ///   - Fetch the active carrier's country code.
    ///   - If carrier is not available, use the locale country code.
    ///
    func fetchUsersCountryCode() async throws -> String {
        // Use ip country code for WPCom accounts
        if !stores.isAuthenticatedWithoutWPCom {
            return try await fetchIPCountryCode()
        }

        // Use carrier country code for non-WPCom accounts
        if let carrierCode = fetchCarrierCountryCode() {
            return carrierCode
        }

        // Use locale country code as a fallback
        return fetchLocaleCountryCode()
    }

    /// Fetches the ip country code using the Account API.
    ///
    func fetchIPCountryCode() async throws -> String {
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

    /// Fetches the country code from the first registered cellular provider.
    ///
    func fetchCarrierCountryCode() -> String? {
        let networkCarrier = CTTelephonyNetworkInfo().serviceSubscriberCellularProviders?.first?.value
        return networkCarrier?.isoCountryCode
    }

    /// Fetches the country code from the current locate.
    ///
    func fetchLocaleCountryCode() -> String {
        Locale.autoupdatingCurrent.identifier
    }
}

private extension UserDefaults {
    @objc dynamic var hasSavedPrivacyBannerSettings: Bool {
        bool(forKey: Key.hasSavedPrivacyBannerSettings.rawValue)
    }
}
