import Foundation
import UIKit
import class WooFoundation.CurrencySettings
import enum WooFoundation.CountryCode
import protocol Experiments.FeatureFlagService
import struct Yosemite.SiteSetting
import protocol Yosemite.StoresManager
import struct Yosemite.SystemPlugin
import enum Yosemite.SystemStatusAction
import enum Yosemite.FeatureFlagAction
import enum Yosemite.SiteSettingsFeature
import enum Yosemite.SettingAction
import enum WooFoundation.CurrencyCode

enum POSIneligibleReason: Equatable {
    case notTablet
    case unsupportedIOSVersion
    case unsupportedWooCommerceVersion
    case systemInformationNotAvailable
    case wooCommercePluginNotFound
    case featureFlagDisabled
    case featureSwitchDisabled
    case featureSwitchSyncFailure
    case unsupportedCountry
    case unsupportedCurrency
    case selfDeallocated
}

enum POSEligibilityState: Equatable {
    case eligible
    case ineligible(reason: POSIneligibleReason)
}

protocol POSEntryPointEligibilityCheckerProtocol {
    func checkEligibility() async -> POSEligibilityState
}

/// Determines whether the POS entry point can be shown based on the selected store and feature gates.
final class POSTabEligibilityChecker: POSEntryPointEligibilityCheckerProtocol {
    func checkEligibility() async -> POSEligibilityState {
        guard #available(iOS 17.0, *) else {
            return .ineligible(reason: .unsupportedIOSVersion)
        }

        guard userInterfaceIdiom == .pad else {
            return .ineligible(reason: .notTablet)
        }

        async let siteSettingsEligibility = checkSiteSettingsEligibility()
        async let featureFlagEligibility = isPointOfSaleFeatureFlagEnabled()

        // Waits for both results.
        let (siteSettingsResult, featureFlagResult) = await (siteSettingsEligibility, featureFlagEligibility)

        // Checks feature flag first.
        switch featureFlagResult {
        case .eligible:
            break
        case .ineligible(let reason):
            return .ineligible(reason: reason)
        }

        // Then checks site settings.
        switch siteSettingsResult {
        case .eligible:
            return .eligible
        case .ineligible(let reason):
            return .ineligible(reason: reason)
        }
    }

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
}

private extension POSTabEligibilityChecker {
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

    func isEligibleFromPluginChecks(systemPlugins: [SystemPlugin], enabledFeatures: [String]?) -> POSEligibilityState {
        guard let wcPlugin = systemPlugins.first(where: { $0.name == Constants.wcPluginName && $0.active }) else {
            return .ineligible(reason: .wooCommercePluginNotFound)
        }

        guard VersionHelpers.isVersionSupported(version: wcPlugin.version,
                                                minimumRequired: Constants.wcPluginMinimumVersion) else {
            return .ineligible(reason: .unsupportedWooCommerceVersion)
        }

        if VersionHelpers.isVersionSupported(version: wcPlugin.version,
                                             minimumRequired: Constants.wcPluginMinimumVersionWithFeatureSwitch,
                                             includesDevAndBetaVersions: true) {
            // For versions that support the feature switch, checks if the feature switch is enabled.
            guard let enabledFeatures,
                  enabledFeatures.contains(SiteSettingsFeature.pointOfSale.rawValue) else {
                return .ineligible(reason: .featureSwitchDisabled)
            }
            return .eligible
        } else {
            // For versions below 10.0.0, the feature is enabled by default.
            return .eligible
        }
    }
}

private extension POSTabEligibilityChecker {
    func checkSiteSettingsEligibility() async -> POSEligibilityState {
        // Wait for the first site settings refresh
        await waitForSiteSettingsRefresh()
        
        // Conditions that can change if site settings are synced during the lifetime.
        let countryCode = SiteAddress(siteSettings: siteSettings.siteSettings).countryCode
        let currency = currencySettings.currencyCode

        // Checks country first.
        switch countryCode {
        case .US, .GB:
            break
        default:
            return .ineligible(reason: .unsupportedCountry)
        }

        // Then checks currency.
        switch currency {
        case .USD, .GBP:
            return .eligible
        default:
            return .ineligible(reason: .unsupportedCurrency)
        }
    }

    @MainActor
    func waitForSiteSettingsRefresh() async {
        for await _ in NotificationCenter.default.notifications(named: .selectedSiteSettingsRefreshed, object: siteSettings).map( { $0.name } ) {
            break // Exit after first notification
        }
    }
}

private extension POSTabEligibilityChecker {
    func isPointOfSaleFeatureFlagEnabled() async -> POSEligibilityState {
        // Only whitelisted accounts in WPCOM have the Point of Sale remote feature flag enabled. These can be found at D159901-code
        // If the account is whitelisted, then the remote value takes preference over the local feature flag configuration
        return await withCheckedContinuation { [weak self] continuation in
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
