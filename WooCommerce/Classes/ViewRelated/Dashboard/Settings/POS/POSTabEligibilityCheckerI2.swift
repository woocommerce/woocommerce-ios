import Combine
import Foundation
import UIKit
import class WooFoundation.CurrencySettings
import enum WooFoundation.CountryCode
import enum WooFoundation.CurrencyCode
import protocol Experiments.FeatureFlagService
import struct Yosemite.SiteSetting
import protocol Yosemite.POSEligibilityServiceProtocol
import protocol Yosemite.StoresManager
import class Yosemite.POSEligibilityService
import struct Yosemite.SystemPlugin
import enum Yosemite.FeatureFlagAction
import enum Yosemite.SettingAction
import protocol Yosemite.PluginsServiceProtocol
import class Yosemite.PluginsService

/// Legacy enum containing POS invisible reasons + POSIneligibleReason cases for i1.
private enum LegacyPOSIneligibleReason: Equatable {
    case notTablet
    case unsupportedIOSVersion
    case unsupportedWooCommerceVersion(minimumVersion: String)
    case siteSettingsNotAvailable
    case wooCommercePluginNotFound
    case featureFlagDisabled
    case featureSwitchDisabled
    case featureSwitchSyncFailure
    case unsupportedCountry(supportedCountries: [CountryCode])
    case unsupportedCurrency(supportedCurrencies: [CurrencyCode])
    case selfDeallocated
}

/// Legacy POS eligibility state for i1.
private enum LegacyPOSEligibilityState: Equatable {
    case eligible
    case ineligible(reason: LegacyPOSIneligibleReason)
}

final class POSTabEligibilityCheckerI2: POSEntryPointEligibilityCheckerProtocol {
    private var siteSettingsEligibility: POSEligibilityState?
    private var featureFlagEligibility: POSEligibilityState?

    private let siteID: Int64
    private let userInterfaceIdiom: UIUserInterfaceIdiom
    private let siteSettings: SelectedSiteSettingsProtocol
    private let pluginsService: PluginsServiceProtocol
    private let eligibilityService: POSEligibilityServiceProtocol
    private let stores: StoresManager
    private let featureFlagService: FeatureFlagService

    init(siteID: Int64,
         userInterfaceIdiom: UIUserInterfaceIdiom = UIDevice.current.userInterfaceIdiom,
         siteSettings: SelectedSiteSettingsProtocol = ServiceLocator.selectedSiteSettings,
         pluginsService: PluginsServiceProtocol = PluginsService(storageManager: ServiceLocator.storageManager),
         eligibilityService: POSEligibilityServiceProtocol = POSEligibilityService(),
         stores: StoresManager = ServiceLocator.stores,
         featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService) {
        self.siteID = siteID
        self.userInterfaceIdiom = userInterfaceIdiom
        self.siteSettings = siteSettings
        self.pluginsService = pluginsService
        self.eligibilityService = eligibilityService
        self.stores = stores
        self.featureFlagService = featureFlagService
    }

    /// Checks the initial visibility of the POS tab without dependance on network requests.
    func checkInitialVisibility() -> Bool {
        eligibilityService.loadCachedPOSTabVisibility(siteID: siteID) ?? false
    }

    /// Determines whether the POS entry point can be shown based on the selected store and feature gates.
    func checkEligibility() async -> POSEligibilityState {
        guard featureFlagService.isFeatureFlagEnabled(.pointOfSaleAsATabi2) else {
            // For i1, POS tab visibility check is equal to eligibility check.
            return .eligible
        }

        guard #available(iOS 17.0, *) else {
            return .ineligible(reason: .unsupportedIOSVersion)
        }

        async let siteSettingsEligibility = checkSiteSettingsEligibility()
        async let pluginEligibility = checkPluginEligibility()

        // Checks site settings first since it's likely to complete fastest.
        switch await siteSettingsEligibility {
        case .eligible:
            break
        case .ineligible(let reason):
            return .ineligible(reason: reason)
        }

        // Finally checks plugin eligibility.
        switch await pluginEligibility {
        case .eligible:
            return .eligible
        case .ineligible(let reason):
            return .ineligible(reason: reason)
        }
    }

    /// Checks the final visibility of the POS tab.
    func checkVisibility() async -> Bool {
        if featureFlagService.isFeatureFlagEnabled(.pointOfSaleAsATabi2) {
            return await checkVisibilityBasedOnCountryAndRemoteFeatureFlag()
        } else {
            let eligibility = await checkEligibilityForI1()
            return eligibility == .eligible
        }
    }
}

private extension POSTabEligibilityCheckerI2 {
    /// Determines whether the site is eligible for POS checking all conditions.
    func checkEligibilityForI1() async -> LegacyPOSEligibilityState {
        switch checkDeviceEligibilityForI1() {
        case .eligible:
            break
        case .ineligible(let reason):
            return .ineligible(reason: reason)
        }

        async let siteSettingsEligibility = checkSiteSettingsEligibilityForI1()
        async let featureFlagEligibility = checkRemoteFeatureEligibility().toLegacyPOSEligibilityState
        async let pluginEligibility = checkPluginEligibility().toLegacyPOSEligibilityState

        // Checks site settings first since it's likely to complete fastest.
        switch await siteSettingsEligibility {
        case .eligible:
            break
        case .ineligible(let reason):
            return .ineligible(reason: reason)
        }

        // Then checks feature flag.
        switch await featureFlagEligibility {
        case .eligible:
            break
        case .ineligible(let reason):
            return .ineligible(reason: reason)
        }

        // Finally checks plugin eligibility.
        switch await pluginEligibility {
        case .eligible:
            return .eligible
        case .ineligible(let reason):
            return .ineligible(reason: reason)
        }
    }

    func checkDeviceEligibilityForI1() -> LegacyPOSEligibilityState {
        guard #available(iOS 17.0, *) else {
            return .ineligible(reason: .unsupportedIOSVersion)
        }

        guard userInterfaceIdiom == .pad else {
            return .ineligible(reason: .notTablet)
        }

        return .eligible
    }
}

private extension POSTabEligibilityCheckerI2 {
    func checkVisibilityBasedOnCountryAndRemoteFeatureFlag() async -> Bool {
        guard userInterfaceIdiom == .pad else {
            return false
        }

        async let siteSettingsEligibility = waitAndCheckSiteSettingsEligibility()
        async let featureFlagEligibility = checkRemoteFeatureEligibility()

        switch await siteSettingsEligibility {
        case .ineligible(.unsupportedCountry):
            return false
        default:
            break
        }

        switch await featureFlagEligibility {
        case .eligible:
            return true
        case .ineligible:
            return false
        }
    }
}

// MARK: - WC Plugin Related Eligibility Check

private extension POSTabEligibilityCheckerI2 {
    func checkPluginEligibility() async -> POSEligibilityState {
        let wcPlugin = await fetchWooCommercePlugin(siteID: siteID)

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

        // For versions that support the feature switch, checks if the feature switch is enabled.
        return await checkFeatureSwitchEnabled(siteID: siteID)
    }

    @MainActor
    func fetchWooCommercePlugin(siteID: Int64) async -> SystemPlugin {
        await pluginsService.waitForPluginInStorage(siteID: siteID, pluginName: Constants.wcPluginName, isActive: true)
    }

    @MainActor
    func checkFeatureSwitchEnabled(siteID: Int64) async -> POSEligibilityState {
        await withCheckedContinuation { [weak self] continuation in
            guard let self else {
                return continuation.resume(returning: .ineligible(reason: .selfDeallocated))
            }
            let action = SettingAction.isFeatureEnabled(siteID: siteID, feature: .pointOfSale) { result in
                switch result {
                case .success(let isEnabled):
                    continuation.resume(returning: isEnabled ? .eligible : .ineligible(reason: .featureSwitchDisabled))
                case .failure:
                    continuation.resume(returning: .ineligible(reason: .featureSwitchSyncFailure))
                }
            }
            stores.dispatch(action)
        }
    }
}

// MARK: - Site Settings Related Eligibility Check

private extension POSTabEligibilityCheckerI2 {
    enum SiteSettingsEligibilityState {
        case eligible
        case ineligible(reason: SiteSettingsIneligibleReason)
    }

    enum SiteSettingsIneligibleReason {
        case siteSettingsNotAvailable
        case unsupportedCountry(supportedCountries: [CountryCode])
        case unsupportedCurrency(supportedCurrencies: [CurrencyCode])
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
            case let .unsupportedCurrency(supportedCurrencies: supportedCurrencies):
                return .ineligible(reason: .unsupportedCurrency(supportedCurrencies: supportedCurrencies))
            }
        }
    }

    func checkSiteSettingsEligibilityForI1() async -> LegacyPOSEligibilityState {
        let siteSettingsEligibility = await waitAndCheckSiteSettingsEligibility()
        switch siteSettingsEligibility {
        case .eligible:
            return .eligible
        case .ineligible(reason: let reason):
            switch reason {
            case .siteSettingsNotAvailable:
                return .ineligible(reason: .siteSettingsNotAvailable)
            case let .unsupportedCountry(supportedCountries: supportedCountries):
                return .ineligible(reason: .unsupportedCountry(supportedCountries: supportedCountries))
            case let .unsupportedCurrency(supportedCurrencies: supportedCurrencies):
                return .ineligible(reason: .unsupportedCurrency(supportedCurrencies: supportedCurrencies))
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
        let supportedCountries: [CountryCode] = [.US, .GB]
        let supportedCurrencies: [CountryCode: [CurrencyCode]] = [.US: [.USD],
                                                                  .GB: [.GBP]]

        // Checks country first.
        guard supportedCountries.contains(countryCode) else {
            return .ineligible(reason: .unsupportedCountry(supportedCountries: supportedCountries))
        }

        let supportedCurrenciesForCountry = supportedCurrencies[countryCode] ?? []
        guard supportedCurrenciesForCountry.contains(currencyCode) else {
            return .ineligible(reason: .unsupportedCurrency(supportedCurrencies: supportedCurrenciesForCountry))
        }
        return .eligible
    }
}

// MARK: - Remote Feature Flag Eligibility Check

private extension POSTabEligibilityCheckerI2 {
    enum RemoteFeatureFlagEligibilityState {
        case eligible
        case ineligible(reason: RemoteFeatureFlagIneligibleReason)
    }

    enum RemoteFeatureFlagIneligibleReason {
        case selfDeallocated
        case featureFlagDisabled
    }

    @MainActor
    func checkRemoteFeatureEligibility() async -> RemoteFeatureFlagEligibilityState {
        // Only whitelisted accounts in WPCOM have the Point of Sale remote feature flag enabled. These can be found at D159901-code
        // If the account is whitelisted, then the remote value takes preference over the local feature flag configuration
        await withCheckedContinuation { [weak self] continuation in
            guard let self else {
                return continuation.resume(returning: .ineligible(reason: .selfDeallocated))
            }
            let action = FeatureFlagAction.isRemoteFeatureFlagEnabled(.pointOfSale, defaultValue: false) { [weak self] result in
                guard let self else {
                    return continuation.resume(returning: .ineligible(reason: .selfDeallocated))
                }
                switch result {
                case true:
                    // The site is whitelisted.
                    continuation.resume(returning: .eligible)
                case false:
                    // When the site is not whitelisted, check the local feature flag configuration.
                    let localFeatureFlag = featureFlagService.isFeatureFlagEnabled(.pointOfSale)
                    continuation.resume(returning: localFeatureFlag ? .eligible : .ineligible(reason: .featureFlagDisabled))
                }
            }
            self.stores.dispatch(action)
        }
    }
}

private extension POSTabEligibilityCheckerI2 {
    enum Constants {
        static let wcPluginName = "WooCommerce"
        static let wcPluginMinimumVersion = "9.6.0-beta"
        static let wcPluginMinimumVersionWithFeatureSwitch = "10.0.0"
    }
}

private extension POSIneligibleReason {
    var toLegacyPOSIneligibilityReason: LegacyPOSIneligibleReason {
        switch self {
        case .unsupportedIOSVersion:
            return .unsupportedIOSVersion
        case .unsupportedWooCommerceVersion(let minimumVersion):
            return .unsupportedWooCommerceVersion(minimumVersion: minimumVersion)
        case .siteSettingsNotAvailable:
            return .siteSettingsNotAvailable
        case .wooCommercePluginNotFound:
            return .wooCommercePluginNotFound
        case .featureSwitchDisabled:
            return .featureSwitchDisabled
        case .featureSwitchSyncFailure:
            return .featureSwitchSyncFailure
        case .unsupportedCurrency(let supportedCurrencies):
            return .unsupportedCurrency(supportedCurrencies: supportedCurrencies)
        case .selfDeallocated:
            return .selfDeallocated
        }
    }
}

private extension POSEligibilityState {
    var toLegacyPOSEligibilityState: LegacyPOSEligibilityState {
        switch self {
        case .eligible:
            return .eligible
        case .ineligible(let reason):
            return .ineligible(reason: reason.toLegacyPOSIneligibilityReason)
        }
    }
}

private extension POSTabEligibilityCheckerI2.RemoteFeatureFlagEligibilityState {
    var toLegacyPOSEligibilityState: LegacyPOSEligibilityState {
        switch self {
        case .eligible:
            return .eligible
        case .ineligible(let reason):
            switch reason {
            case .selfDeallocated:
                return .ineligible(reason: .selfDeallocated)
            case .featureFlagDisabled:
                return .ineligible(reason: .featureFlagDisabled)
            }
        }
    }
}
