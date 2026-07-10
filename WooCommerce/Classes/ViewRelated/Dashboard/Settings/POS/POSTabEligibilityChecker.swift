import Foundation
import UIKit
import class WooFoundation.CurrencySettings
import enum WooFoundation.CountryCode
import enum WooFoundation.CurrencyCode
import struct Yosemite.SiteSetting
import struct Yosemite.Site
import protocol Yosemite.StoresManager
import struct Yosemite.SystemPlugin
import enum Yosemite.FeatureFlagAction
import enum Yosemite.SettingAction
import protocol Yosemite.POSSystemStatusServiceProtocol
import class Yosemite.POSSystemStatusService
import protocol Yosemite.POSSiteSettingServiceProtocol
import class Yosemite.POSSiteSettingService
import class Yosemite.SiteAddress
import enum Networking.SiteSettingsFeature
import class WooFoundation.VersionHelpers
import protocol PointOfSale.POSEntryPointEligibilityCheckerProtocol
import enum PointOfSale.POSEligibilityState
import enum PointOfSale.POSIneligibleReason
import protocol WooFoundation.ConnectivityObserver
import enum Yosemite.POSCountryCurrencyValidator
import protocol Yosemite.CardPresentPaymentsCountryExpansionEligibilityServiceProtocol
import class Yosemite.CardPresentPaymentsCountryExpansionEligibilityService
import protocol Yosemite.POSEligibilityServiceProtocol
import class Yosemite.POSEligibilityService
import protocol Yosemite.POSLocalCatalogEligibilityServiceProtocol
import protocol Yosemite.POSCatalogSyncStatusCheckerProtocol
import struct Yosemite.POSCatalogSyncStatusChecker

final class POSTabEligibilityChecker: POSEntryPointEligibilityCheckerProtocol {
    private let siteID: Int64
    private let siteSettings: SelectedSiteSettingsProtocol
    private let stores: StoresManager
    private let systemStatusService: POSSystemStatusServiceProtocol
    private let siteSettingService: POSSiteSettingServiceProtocol
    private let appPasswordSupportState: ApplicationPasswordsExperimentState
    private let expansionEligibilityService: CardPresentPaymentsCountryExpansionEligibilityServiceProtocol
    private let connectivityObserver: ConnectivityObserver
    private let eligibilityService: POSEligibilityServiceProtocol
    private let localCatalogEligibilityService: POSLocalCatalogEligibilityServiceProtocol?
    private let syncStatusChecker: POSCatalogSyncStatusCheckerProtocol

    init(siteID: Int64,
         siteSettings: SelectedSiteSettingsProtocol = ServiceLocator.selectedSiteSettings,
         stores: StoresManager = ServiceLocator.stores,
         systemStatusService: POSSystemStatusServiceProtocol? = nil,
         siteSettingService: POSSiteSettingServiceProtocol? = nil,
         connectivityObserver: ConnectivityObserver = ServiceLocator.connectivityObserver,
         expansionEligibilityService: CardPresentPaymentsCountryExpansionEligibilityServiceProtocol = CardPresentPaymentsCountryExpansionEligibilityService(),
         eligibilityService: POSEligibilityServiceProtocol = POSEligibilityService(),
         localCatalogEligibilityService: POSLocalCatalogEligibilityServiceProtocol? = nil,
         syncStatusChecker: POSCatalogSyncStatusCheckerProtocol? = nil) {
        self.siteID = siteID
        self.siteSettings = siteSettings
        self.stores = stores
        self.connectivityObserver = connectivityObserver
        self.expansionEligibilityService = expansionEligibilityService
        self.eligibilityService = eligibilityService
        self.localCatalogEligibilityService = localCatalogEligibilityService ?? stores.posCatalogEligibilityChecker
        self.syncStatusChecker = syncStatusChecker ?? POSCatalogSyncStatusChecker(grdbManager: ServiceLocator.grdbManager)
        self.appPasswordSupportState = ApplicationPasswordsExperimentState()

        let credentials = stores.sessionManager.defaultCredentials
        let selectedSite = stores.sessionManager.defaultSitePublisher.map { $0?.toJetpackSite() }.eraseToAnyPublisher()
        let appPasswordSupport = appPasswordSupportState.$isAvailableAndEnabled.eraseToAnyPublisher()
        self.systemStatusService = systemStatusService ?? POSSystemStatusService(
            credentials: credentials,
            selectedSite: selectedSite,
            appPasswordSupportState: appPasswordSupport,
            storageManager: ServiceLocator.storageManager
        )
        self.siteSettingService = siteSettingService ?? POSSiteSettingService(
            credentials: credentials,
            selectedSite: selectedSite,
            appPasswordSupportState: appPasswordSupport
        )
    }

    /// Determines whether the POS entry point can be shown based on the selected store and feature gates.
    ///
    /// Matches Android's cache-tolerant launchability check: a store that previously passed the
    /// eligibility checks and has a fully synced local catalog can run POS from local data without
    /// waiting on remote checks, online or offline. Background refreshes pass `forceRemoteCheck`
    /// to re-validate remotely and detect a store that became ineligible.
    func checkEligibility(forceRemoteCheck: Bool) async -> POSEligibilityState {
        // Bypass eligibility checks for screenshot tests
        if ProcessConfiguration.shouldBypassPOSEligibilityChecks {
            return .eligible
        }

        guard connectivityObserver.currentStatus != .notReachable else {
            // Offline, only report the missing connection when local state cannot support POS.
            return await canRunFromLocalCatalog() ? .eligible : .ineligible(reason: .noInternetConnection)
        }

        if !forceRemoteCheck, await canRunFromLocalCatalog() {
            return .eligible
        }

        let state = await checkOnlineEligibility()
        recordLastKnownEligibilityIfDefinite(state)
        return state
    }

    private func checkOnlineEligibility() async -> POSEligibilityState {
        async let siteSettingsEligibility = checkSiteSettingsEligibility()
        async let pluginEligibility = checkPluginEligibility()

        switch await siteSettingsEligibility {
        case .eligible:
            break
        case .ineligible(let reason):
            return .ineligible(reason: reason)
        }

        switch await pluginEligibility {
        case .eligible:
            return .eligible
        case .ineligible(let reason):
            return .ineligible(reason: reason)
        }
    }

    func refreshEligibility(ineligibleReason: POSIneligibleReason) async throws -> POSEligibilityState {
        switch ineligibleReason {
        case .siteSettingsNotAvailable, .unsupportedCurrency:
            do {
                try await syncSiteSettingsRemotely()
                return await checkEligibility(forceRemoteCheck: false)
            } catch POSTabEligibilityCheckerError.selfDeallocated {
                return .ineligible(reason: .selfDeallocated)
            } catch {
                if error.isConnectivityError {
                    return .ineligible(reason: .noInternetConnection)
                }
                throw error
            }
        case .unsupportedWooCommerceVersion, .wooCommercePluginNotFound, .noInternetConnection:
            return await checkEligibility(forceRemoteCheck: false)
        case .featureSwitchDisabled:
            _ = try await siteSettingService.setFeature(siteID: siteID, feature: .pointOfSale, enabled: true)
            return await checkEligibility(forceRemoteCheck: false)
        case .selfDeallocated:
            return await checkEligibility(forceRemoteCheck: false)
        }
    }
}

// MARK: - Eligibility From Local State

private extension POSTabEligibilityChecker {
    /// Whether locally available state can support POS without remote checks:
    /// no definite ineligibility was recorded by a previous online check, the locally synced
    /// WooCommerce plugin (when available) still meets the requirements, the local catalog
    /// feature is enabled, and a full catalog sync completed at some point so the local
    /// catalog can serve items.
    func canRunFromLocalCatalog() async -> Bool {
        // `!= false` rather than `== true`: nil (no definite result recorded yet, e.g. right
        // after updating to this version) must pass, because a completed full sync — required
        // below — already implies the store was eligible when the catalog synced. The flag is
        // a veto for stores definitely known to be ineligible, not a required positive.
        guard eligibilityService.loadLastKnownPOSEligibility(siteID: siteID) != false,
              await cachedPluginSupportsPOS(),
              let localCatalogEligibilityService,
              await localCatalogEligibilityService.isLocalCatalogFeatureEnabled(),
              await syncStatusChecker.hasCompletedFullSync(for: siteID) else {
            return false
        }
        return true
    }

    /// Validates against plugin data synced into local storage by any part of the app, like
    /// Android's cached version check: a plugin known locally to be inactive or below the minimum
    /// version blocks entry from local state. When no plugin data has been synced, falls back to
    /// the other locally recorded positive signals.
    @MainActor
    func cachedPluginSupportsPOS() -> Bool {
        guard let wcPlugin = systemStatusService.loadCachedWooCommercePlugin(siteID: siteID) else {
            return true
        }
        return wcPlugin.active && VersionHelpers.isVersionSupported(version: wcPlugin.version,
                                                                    minimumRequired: Constants.wcPluginMinimumVersion)
    }

    /// Persists definite results from online checks so offline eligibility stays available
    /// across launches, and is invalidated once the store is definitely known to be ineligible.
    /// Indeterminate results (e.g. settings unavailable) leave the last known value untouched.
    func recordLastKnownEligibilityIfDefinite(_ state: POSEligibilityState) {
        switch state {
        case .eligible:
            eligibilityService.cacheLastKnownPOSEligibility(siteID: siteID, isEligible: true)
        case .ineligible(let reason):
            guard reason.isDefiniteIneligibility else {
                return
            }
            eligibilityService.cacheLastKnownPOSEligibility(siteID: siteID, isEligible: false)
        }
    }
}

private extension POSIneligibleReason {
    /// Whether the reason reflects the store's actual state rather than a failure to determine it.
    var isDefiniteIneligibility: Bool {
        switch self {
        case .unsupportedWooCommerceVersion, .wooCommercePluginNotFound, .featureSwitchDisabled, .unsupportedCurrency:
            return true
        case .noInternetConnection, .siteSettingsNotAvailable, .selfDeallocated:
            return false
        }
    }
}

// MARK: - WC Plugin Related Eligibility Check

private extension POSTabEligibilityChecker {
    /// Checks the eligibility of the WooCommerce plugin and plugin version based POS feature switch value.
    ///
    /// - Parameter pluginEligibility: An optional parameter that can provide pre-fetched plugin eligibility state.
    /// - Returns: The eligibility state for POS based on the WooCommerce plugin and POS feature switch.
    func checkPluginEligibility() async -> POSEligibilityState {
        do {
            let info = try await systemStatusService.loadWooCommercePluginAndPOSFeatureSwitch(siteID: siteID)
            let wcPluginEligibility = checkWooCommercePluginEligibility(wcPlugin: info.wcPlugin)
            switch wcPluginEligibility {
            case .eligible:
                return .eligible
            case .ineligible(let reason):
                return .ineligible(reason: reason)
            case .pendingFeatureSwitchCheck:
                let isFeatureSwitchEnabled = info.featureValue == true
                return isFeatureSwitchEnabled ? .eligible : .ineligible(reason: .featureSwitchDisabled)
            }
        } catch {
            if error.isConnectivityError {
                return .ineligible(reason: .noInternetConnection)
            }
            return .ineligible(reason: .wooCommercePluginNotFound)
        }
    }

    enum PluginEligibilityState {
        case eligible
        case ineligible(reason: POSIneligibleReason)
        case pendingFeatureSwitchCheck
    }

    func checkWooCommercePluginEligibility(wcPlugin: SystemPlugin?) -> PluginEligibilityState {
        guard let wcPlugin, wcPlugin.active else {
            return .ineligible(reason: .wooCommercePluginNotFound)
        }

        guard VersionHelpers.isVersionSupported(version: wcPlugin.version,
                                                minimumRequired: Constants.wcPluginMinimumVersion) else {
            return .ineligible(reason: .unsupportedWooCommerceVersion(minimumVersion: Constants.wcPluginMinimumVersion))
        }

        // For versions below 10.0.0, the feature is enabled by default.
        let isFeatureSwitchSupported = VersionHelpers.isVersionSupported(version: wcPlugin.version,
                                                                         minimumRequired: Constants.wcPluginMinimumVersionWithFeatureSwitch,
                                                                         includesDevAndBetaVersions: true)
        if !isFeatureSwitchSupported {
            return .eligible
        }

        // For versions that support the feature switch, checks if the feature switch is enabled separately.
        return .pendingFeatureSwitchCheck
    }
}

// MARK: - Site Settings Related Eligibility Check

private extension POSTabEligibilityChecker {
    enum SiteSettingsEligibilityState {
        case eligible
        case ineligible(reason: SiteSettingsIneligibleReason)
    }

    enum SiteSettingsIneligibleReason {
        case siteSettingsNotAvailable
        case unsupportedCountry(supportedCountries: [CountryCode])
        case unsupportedCurrency(countryCode: CountryCode, supportedCurrencies: [CurrencyCode])
    }

    func checkSiteSettingsEligibility() async -> POSEligibilityState {
        let siteSettingsEligibility = await waitAndCheckSiteSettingsEligibility()
        switch siteSettingsEligibility {
        case .eligible:
            return .eligible
        case .ineligible(reason: let reason):
            switch reason {
            case .siteSettingsNotAvailable, .unsupportedCountry:
                // This is an edge case where the store country is expected to be eligible from the visilibity check, but site settings might have
                // changed to an unsupported country during the session. In this case, we return an ineligible reason that prompts the merchant to
                // relaunch the app.
                return .ineligible(reason: .siteSettingsNotAvailable)
            case let .unsupportedCurrency(countryCode: countryCode, supportedCurrencies: supportedCurrencies):
                return .ineligible(reason: .unsupportedCurrency(countryCode: countryCode, supportedCurrencies: supportedCurrencies))
            }
        }
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

        return isEligibleFromCountryAndCurrencyCode(countryCode: countryCode, currencyCode: currencyCode)
    }

    func waitForSiteSettingsRefresh() async -> [SiteSetting] {
        for await siteSettings in siteSettings.settingsStream.values {
            guard siteSettings.siteID == siteID, siteSettings.settings.isNotEmpty, siteSettings.source != .initialLoad else {
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
            currencyCode: currencyCode,
            siteID: siteID,
            eligibilityService: expansionEligibilityService
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

    @MainActor
    func syncSiteSettingsRemotely() async throws {
        try await withCheckedThrowingContinuation { [weak self] (continuation: CheckedContinuation<Void, Error>) in
            guard let self else {
                return continuation.resume(throwing: POSTabEligibilityCheckerError.selfDeallocated)
            }
            stores.dispatch(SettingAction.synchronizeGeneralSiteSettings(siteID: siteID) { [weak self] error in
                guard let self else {
                    return continuation.resume(throwing: POSTabEligibilityCheckerError.selfDeallocated)
                }
                if let error {
                    return continuation.resume(throwing: error)
                }
                siteSettings.refresh()
                continuation.resume(returning: ())
            })
        }
    }
}

private enum POSTabEligibilityCheckerError: Error {
    case selfDeallocated
}

private extension POSTabEligibilityChecker {
    enum Constants {
        static let wcPlugin = "woocommerce/woocommerce.php"
        static let wcPluginMinimumVersion = "9.6.0-beta"
        static let wcPluginMinimumVersionWithFeatureSwitch = "10.0.0"
    }
}
