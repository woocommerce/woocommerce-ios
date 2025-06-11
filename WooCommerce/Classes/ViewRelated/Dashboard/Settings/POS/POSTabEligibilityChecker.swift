import Foundation
import UIKit
import class WooFoundation.CurrencySettings
import enum WooFoundation.CountryCode
import enum WooFoundation.CurrencyCode
import protocol Experiments.FeatureFlagService
import struct Yosemite.SiteSetting
import protocol Yosemite.StoresManager
import struct Yosemite.SystemPlugin
import enum Yosemite.SystemStatusAction
import enum Yosemite.FeatureFlagAction
import enum Yosemite.SettingAction

/// Represents the reasons why a site may be ineligible for POS.
enum POSIneligibleReason: Equatable {
    case notTablet
    case unsupportedIOSVersion
    case unsupportedWooCommerceVersion
    case siteSettingsNotAvailable
    case wooCommercePluginNotFound
    case featureFlagDisabled
    case featureSwitchDisabled
    case featureSwitchSyncFailure
    case unsupportedCountry
    case unsupportedCurrency
    case selfDeallocated
}

/// Represents the eligibility state for POS.
enum POSEligibilityState: Equatable {
    case eligible
    case ineligible(reason: POSIneligibleReason)
}

protocol POSEntryPointEligibilityCheckerProtocol {
    /// Determines whether the site is eligible for POS.
    func checkEligibility() async -> POSEligibilityState
}

final class POSTabEligibilityChecker: POSEntryPointEligibilityCheckerProtocol {
    private let siteID: Int64
    private let userInterfaceIdiom: UIUserInterfaceIdiom
    private let siteSettings: SelectedSiteSettings
    private let currencySettings: CurrencySettings
    private let stores: StoresManager
    private let featureFlagService: FeatureFlagService

    init(siteID: Int64,
         userInterfaceIdiom: UIUserInterfaceIdiom = UIDevice.current.userInterfaceIdiom,
         siteSettings: SelectedSiteSettings = ServiceLocator.selectedSiteSettings,
         currencySettings: CurrencySettings = ServiceLocator.currencySettings,
         stores: StoresManager = ServiceLocator.stores,
         featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService) {
        self.siteID = siteID
        self.userInterfaceIdiom = userInterfaceIdiom
        self.siteSettings = siteSettings
        self.currencySettings = currencySettings
        self.stores = stores
        self.featureFlagService = featureFlagService
    }

    /// Determines whether the POS entry point can be shown based on the selected store and feature gates.
    func checkEligibility() async -> POSEligibilityState {
        guard #available(iOS 17.0, *) else {
            return .ineligible(reason: .unsupportedIOSVersion)
        }

        guard userInterfaceIdiom == .pad else {
            return .ineligible(reason: .notTablet)
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
}

private extension POSTabEligibilityChecker {
    func checkPluginEligibility() async -> POSEligibilityState {
        let wcPlugin = await fetchWooCommercePlugin(siteID: siteID)

        guard let wcPlugin, wcPlugin.active else {
            return .ineligible(reason: .wooCommercePluginNotFound)
        }

        guard VersionHelpers.isVersionSupported(version: wcPlugin.version,
                                                minimumRequired: Constants.wcPluginMinimumVersion) else {
            return .ineligible(reason: .unsupportedWooCommerceVersion)
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
    func fetchWooCommercePlugin(siteID: Int64) async -> SystemPlugin? {
        await withCheckedContinuation { [weak self] continuation in
            guard let self else {
                return continuation.resume(returning: nil)
            }
            let action = SystemStatusAction.fetchSystemPlugin(siteID: siteID, systemPluginName: Constants.wcPluginName) { wcPlugin in
                continuation.resume(returning: wcPlugin)
            }
            stores.dispatch(action)
        }
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

private extension POSTabEligibilityChecker {
    func checkSiteSettingsEligibility() async -> POSEligibilityState {
        // Waits for the first site settings that matches the given site ID.
        let siteSettings = await waitForSiteSettingsRefresh()
        guard siteSettings.isNotEmpty else {
            return .ineligible(reason: .siteSettingsNotAvailable)
        }

        // Conditions that can change if site settings are synced during the lifetime.
        let countryCode = SiteAddress(siteSettings: siteSettings).countryCode
        let currencyCode = currencySettings.currencyCode

        return isEligibleFromCountryAndCurrencyCode(countryCode: countryCode, currencyCode: currencyCode)
    }

    func waitForSiteSettingsRefresh() async -> [SiteSetting] {
        for await siteSettings in siteSettings.settingsStream {
            guard siteSettings.siteID == siteID else {
                continue
            }
            return siteSettings.settings
        }
        // If we get here, the stream completed without yielding any values for our site ID which is unexpected.
        return []
    }

    func isEligibleFromCountryAndCurrencyCode(countryCode: CountryCode, currencyCode: CurrencyCode) -> POSEligibilityState {
        // Checks country first.
        switch countryCode {
        case .US, .GB:
            break
        default:
            return .ineligible(reason: .unsupportedCountry)
        }

        // Then checks currency.
        switch currencyCode {
        case .USD, .GBP:
            return .eligible
        default:
            return .ineligible(reason: .unsupportedCurrency)
        }
    }
}

private extension POSTabEligibilityChecker {
    @MainActor
    func checkRemoteFeatureEligibility() async -> POSEligibilityState {
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

private extension POSTabEligibilityChecker {
    enum Constants {
        static let wcPluginName = "WooCommerce"
        static let wcPluginMinimumVersion = "9.6.0-beta"
        static let wcPluginMinimumVersionWithFeatureSwitch = "10.0.0"
    }
}
