import Foundation
import UIKit
import class WooFoundation.CurrencySettings
import protocol WooFoundation.ConnectivityObserver
import enum WooFoundation.CountryCode
import enum WooFoundation.CurrencyCode
import protocol Experiments.FeatureFlagService
import struct Yosemite.SiteSetting
import struct Yosemite.Site
import protocol Yosemite.POSEligibilityServiceProtocol
import protocol Yosemite.StoresManager
import class Yosemite.POSEligibilityService
import protocol Yosemite.RemoteFeatureFlagServiceProtocol
import struct Yosemite.RemoteFeatureFlagService
import class Yosemite.SiteAddress
import enum Yosemite.POSCountryCurrencyValidator

final class POSTabVisibilityChecker: POSTabVisibilityCheckerProtocol {
    private let site: Site
    private let userInterfaceIdiom: UIUserInterfaceIdiom
    private let siteSettings: SelectedSiteSettingsProtocol
    private let eligibilityService: POSEligibilityServiceProtocol
    private let remoteFeatureFlagService: RemoteFeatureFlagServiceProtocol
    private let featureFlagService: FeatureFlagService
    private let isOperatingSystemAtLeast: (OperatingSystemVersion) -> Bool
    private let connectivityObserver: ConnectivityObserver

    private static let minimumPhonePOSOperatingSystemVersion = OperatingSystemVersion(majorVersion: 26, minorVersion: 0, patchVersion: 0)

    init(site: Site,
         userInterfaceIdiom: UIUserInterfaceIdiom = UIDevice.current.userInterfaceIdiom,
         siteSettings: SelectedSiteSettingsProtocol = ServiceLocator.selectedSiteSettings,
         eligibilityService: POSEligibilityServiceProtocol = POSEligibilityService(),
         stores: StoresManager = ServiceLocator.stores,
         featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService,
         connectivityObserver: ConnectivityObserver = ServiceLocator.connectivityObserver,
         isOperatingSystemAtLeast: @escaping (OperatingSystemVersion) -> Bool = ProcessInfo.processInfo.isOperatingSystemAtLeast) {
        self.site = site
        self.userInterfaceIdiom = userInterfaceIdiom
        self.siteSettings = siteSettings
        self.eligibilityService = eligibilityService
        self.remoteFeatureFlagService = RemoteFeatureFlagService(stores: stores)
        self.featureFlagService = featureFlagService
        self.isOperatingSystemAtLeast = isOperatingSystemAtLeast
        self.connectivityObserver = connectivityObserver
    }

    /// Checks the initial visibility of the POS tab without dependence on network requests.
    func checkInitialVisibility() -> Bool {
        if ProcessConfiguration.shouldBypassPOSTabVisibilityChecks {
            return true
        }
        guard userInterfaceIdiom != .phone else {
            return false
        }
        return eligibilityService.loadCachedPOSTabVisibility(siteID: site.siteID) ?? false
    }

    /// Checks the initial visibility without the `POSTabVisibilityChecker` instance
    /// Used for the initial state check when a site instance hasn't been loaded but a `siteID` is available
    static func checkInitialVisibility(
        for siteID: Int64,
        userInterfaceIdiom: UIUserInterfaceIdiom = UIDevice.current.userInterfaceIdiom,
        eligibilityService: POSEligibilityServiceProtocol = POSEligibilityService()
    ) -> Bool {
        if ProcessConfiguration.shouldBypassPOSTabVisibilityChecks {
            return true
        }
        guard userInterfaceIdiom != .phone else {
            return false
        }
        return eligibilityService.loadCachedPOSTabVisibility(siteID: siteID) ?? false
    }

    /// Checks the final visibility of the POS tab.
    func checkVisibility() async -> Bool {
        if ProcessConfiguration.shouldBypassPOSTabVisibilityChecks {
            return true
        }
        guard userInterfaceIdiom != .phone || isPhoneOperatingSystemEligible else {
            logNotVisible("phone POS needs iOS \(Self.minimumPhonePOSOperatingSystemVersion.majorVersion) or later")
            return false
        }

        // Offline, fall back to the cached visibility instead of remote checks that would fail
        // or stall, so a previously visible tab stays available for offline POS entry.
        // Unknown connectivity (e.g. before the first path update at cold start) proceeds with
        // the full check so a fresh online launch is not stuck with stale cached visibility.
        if case .notReachable = connectivityObserver.currentStatus {
            guard let cached = eligibilityService.loadCachedPOSTabVisibility(siteID: site.siteID) else {
                logNotVisible("offline with no cached visibility for the site")
                return false
            }
            if !cached {
                logNotVisible("offline, and the last known visibility was hidden")
            }
            return cached
        }

        async let siteSettingsEligibility = waitAndCheckSiteSettingsEligibility()
        async let featureFlagEligibility = checkRemoteFeatureEligibility()

        switch await siteSettingsEligibility {
        case .ineligible(let reason):
            if case .unsupportedCountry = reason {
                logNotVisible(String(describing: reason))
                return false
            }
        default:
            break
        }

        switch await featureFlagEligibility {
        case .eligible:
            return true
        case .ineligible(let reason):
            logNotVisible(String(describing: reason))
            return false
        }
    }

    /// The literal prefix is quoted by the Mobile Status Report's Point of Sale hint line — keep the two in step.
    private func logNotVisible(_ reason: String) {
        DDLogInfo("POS tab not visible for site \(site.siteID): \(reason)")
    }

    private var isPhoneOperatingSystemEligible: Bool {
        isOperatingSystemAtLeast(Self.minimumPhonePOSOperatingSystemVersion)
    }
}

// MARK: - Site Settings Related Eligibility Check

private extension POSTabVisibilityChecker {
    enum SiteSettingsEligibilityState {
        case eligible
        case ineligible(reason: SiteSettingsIneligibleReason)
    }

    enum SiteSettingsIneligibleReason {
        case siteSettingsNotAvailable
        case unsupportedCountry(supportedCountries: [CountryCode])
        case unsupportedCurrency(countryCode: CountryCode, supportedCurrencies: [CurrencyCode])
    }

    func waitAndCheckSiteSettingsEligibility() async -> SiteSettingsEligibilityState {
        // Waits for the first site settings that matches the given site ID.
        let siteSettings = await waitForSiteSettingsRefresh()
        guard siteSettings.isNotEmpty else {
            return .ineligible(reason: .siteSettingsNotAvailable)
        }

        // Conditions that can change if site settings are synced during the lifetime.
        let countryCode = SiteAddress(siteSettings: siteSettings).countryCode
        let currencyCode = CurrencySettings(siteSettings: siteSettings).currencyCode

        // Phone POS is GB-only, except for US stores when the `woo_pos_phone_us` remote flag
        // is enabled — WPCOM whitelists that flag to Automattic accounts so internal testers
        // can use Tap to Pay on US stores ahead of a wider rollout (WOOMOB-3775).
        if userInterfaceIdiom == .phone, countryCode != .GB {
            guard countryCode == .US, await isPhonePointOfSaleUSRemoteFlagEnabled() else {
                return .ineligible(reason: .unsupportedCountry(supportedCountries: [.GB]))
            }
        }

        return isEligibleFromCountryAndCurrencyCode(countryCode: countryCode, currencyCode: currencyCode)
    }

    func isPhonePointOfSaleUSRemoteFlagEnabled() async -> Bool {
        await remoteFeatureFlagService.isEnabled(.phonePointOfSaleUS, defaultValue: false)
    }

    func waitForSiteSettingsRefresh() async -> [SiteSetting] {
        for await siteSettings in siteSettings.settingsStream.values {
            guard siteSettings.siteID == site.siteID, siteSettings.settings.isNotEmpty, siteSettings.source != .initialLoad else {
                continue
            }
            return siteSettings.settings
        }
        // If we get here, the stream completed without yielding any values for our site ID which is unexpected.
        return []
    }

    func isEligibleFromCountryAndCurrencyCode(countryCode: CountryCode, currencyCode: CurrencyCode) -> SiteSettingsEligibilityState {
        let validationResult = POSCountryCurrencyValidator.validate(
            countryCode: countryCode,
            currencyCode: currencyCode
        )

        switch validationResult {
        case .eligible:
            return .eligible
        case .ineligible(let reason):
            switch reason {
            case .unsupportedCountry(let supportedCountries):
                return .ineligible(reason: .unsupportedCountry(supportedCountries: supportedCountries))
            case .unsupportedCurrency(let countryCode, let supportedCurrencies):
                return .ineligible(reason: .unsupportedCurrency(countryCode: countryCode, supportedCurrencies: supportedCurrencies))
            }
        }
    }
}

// MARK: - Remote Feature Flag Eligibility Check

private extension POSTabVisibilityChecker {
    enum RemoteFeatureFlagEligibilityState: Equatable {
        case eligible
        case ineligible(reason: RemoteFeatureFlagIneligibleReason)
    }

    enum RemoteFeatureFlagIneligibleReason: Equatable {
        case featureFlagDisabled
    }

    func checkRemoteFeatureEligibility() async -> RemoteFeatureFlagEligibilityState {
        // Only whitelisted accounts in WPCOM have the Point of Sale remote feature flag enabled. These can be found at D159901-code
        // If the account is whitelisted, then the remote value takes preference over the local feature flag configuration
        if await remoteFeatureFlagService.isEnabled(.pointOfSale, defaultValue: false) {
            return .eligible
        }
        // When the site is not whitelisted, check the local feature flag configuration.
        return featureFlagService.isFeatureFlagEnabled(.pointOfSale) ? .eligible : .ineligible(reason: .featureFlagDisabled)
    }
}
