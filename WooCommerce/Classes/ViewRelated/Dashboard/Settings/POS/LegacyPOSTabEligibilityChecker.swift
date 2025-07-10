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

/// POS tab eligibility checker for i1. Will be replaced by `POSTabEligibilityCheckerI2` when removing `pointOfSaleAsATabi2` feature flag.
final class LegacyPOSTabEligibilityChecker: POSEntryPointEligibilityCheckerProtocol {
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
        .eligible
    }

    private func checkI1Eligibility() async -> LegacyPOSEligibilityState {
        switch checkDeviceEligibility() {
        case .eligible:
            break
        case .ineligible(let reason):
            return .ineligible(reason: reason)
        }

        async let siteSettingsEligibility = checkSiteSettingsEligibility()
        async let featureFlagEligibility = checkRemoteFeatureEligibility()
        async let pluginEligibility = checkPluginEligibility()

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

    /// Checks the final visibility of the POS tab.
    func checkVisibility() async -> Bool {
        let eligibility = await checkI1Eligibility()
        return eligibility == .eligible
    }

    func refreshEligibility(ineligibleReason: POSIneligibleReason) async throws -> POSEligibilityState {
        assertionFailure("POS as a tab i1 implementation should not refresh eligibility as the eligibility check is performed in the visibility check.")
        return .eligible
    }
}

private extension LegacyPOSTabEligibilityChecker {
    func checkDeviceEligibility() -> LegacyPOSEligibilityState {
        guard #available(iOS 17.0, *) else {
            return .ineligible(reason: .unsupportedIOSVersion)
        }

        guard userInterfaceIdiom == .pad else {
            return .ineligible(reason: .notTablet)
        }

        return .eligible
    }
}

// MARK: - WC Plugin Related Eligibility Check

private extension LegacyPOSTabEligibilityChecker {
    func checkPluginEligibility() async -> LegacyPOSEligibilityState {
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
    func checkFeatureSwitchEnabled(siteID: Int64) async -> LegacyPOSEligibilityState {
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

private extension LegacyPOSTabEligibilityChecker {
    func checkSiteSettingsEligibility() async -> LegacyPOSEligibilityState {
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

    func isEligibleFromCountryAndCurrencyCode(countryCode: CountryCode, currencyCode: CurrencyCode) -> LegacyPOSEligibilityState {
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

private extension LegacyPOSTabEligibilityChecker {
    @MainActor
    func checkRemoteFeatureEligibility() async -> LegacyPOSEligibilityState {
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

private extension LegacyPOSTabEligibilityChecker {
    enum Constants {
        static let wcPluginName = "WooCommerce"
        static let wcPluginMinimumVersion = "9.6.0-beta"
        static let wcPluginMinimumVersionWithFeatureSwitch = "10.0.0"
    }
}
