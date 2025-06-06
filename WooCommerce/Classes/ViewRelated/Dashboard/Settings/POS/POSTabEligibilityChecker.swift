import Combine
import Foundation
import UIKit
import class WooFoundation.CurrencySettings
import enum WooFoundation.CountryCode
import protocol Experiments.FeatureFlagService
import struct Yosemite.SiteSetting
import protocol Yosemite.StoresManager
import struct Yosemite.SiteInformation
import enum Yosemite.SystemStatusAction
import enum Yosemite.FeatureFlagAction
import enum Yosemite.SiteSettingsFeature
import enum Yosemite.SettingAction

enum POSIneligibleReason: Equatable {
    case notTablet
    case unsupportedIOSVersion
    case unsupportedWooCommerceVersion
    case systemInformationNotAvailable
    case wooCommercePluginNotFound
    case featureSwitchDisabled
    case featureSwitchSyncFailure
    case featureFlagDisabled
    case unsupportedCountry
    case unsupportedCurrency
    case selfDeallocated
}

enum POSEligibilityState: Equatable {
    case eligible
    case ineligible(reason: POSIneligibleReason)
}

protocol POSTabEligibilityCheckerProtocol {
    /// As POS eligibility can change from site settings and card payment onboarding state, it's recommended to observe the eligibility value.
    var isEligible: AnyPublisher<POSEligibilityState, Never> { get }
}

/// Determines whether the POS entry point can be shown based on the selected store and feature gates.
final class POSTabEligibilityChecker: POSTabEligibilityCheckerProtocol {
    var isEligible: AnyPublisher<POSEligibilityState, Never> {
        // Conditions that are fixed for its lifetime.
        let isTablet = userInterfaceIdiom == .pad
        guard isTablet else {
            return Just(.ineligible(reason: .notTablet))
                .eraseToAnyPublisher()
        }

        guard #available(iOS 17.0, *) else {
            return Just(.ineligible(reason: .unsupportedIOSVersion))
                .eraseToAnyPublisher()
        }

        return Publishers.CombineLatest3(
            isPointOfSaleFeatureFlagEnabled,
            siteEligibilityPublisher,
            siteSettingsEligibilityPublisher
        )
        .map { featureFlagState, siteEligibility, siteSettingsEligibility -> POSEligibilityState in
            switch siteSettingsEligibility {
            case .eligible:
                break
            case .ineligible(let reason):
                return .ineligible(reason: reason)
            }

            switch featureFlagState {
            case .disabled(let reason):
                return .ineligible(reason: reason)
            case .enabled:
                break
            }

            switch siteEligibility {
            case .eligible:
                return .eligible
            case .ineligible(let reason):
                return .ineligible(reason: reason)
            }
        }
        .eraseToAnyPublisher()
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
    var siteEligibilityPublisher: AnyPublisher<POSEligibilityState, Never> {
        stores.siteInformation
            .map { [weak self] siteInformation -> POSEligibilityState in
                guard let self else { return .ineligible(reason: .selfDeallocated) }
                return isEligibleFromSiteChecks(siteInformation: siteInformation)
            }
            .eraseToAnyPublisher()
    }

    func isEligibleFromSiteChecks(siteInformation: SiteInformation?) -> POSEligibilityState {
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
            break
        default:
            return .ineligible(reason: .unsupportedCurrency)
        }

        guard let siteInformation, siteInformation.siteID == siteID else {
            return .ineligible(reason: .systemInformationNotAvailable)
        }

        guard let wcPlugin = siteInformation.systemInformation?.systemPlugins.first(where: { $0.name == Constants.wcPluginName && $0.active }) else {
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
            guard let enabledFeatures = siteInformation.systemInformation?.enabledFeatures,
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
    private var siteSettingsEligibilityPublisher: AnyPublisher<POSEligibilityState, Never> {
        NotificationCenter.default.publisher(for: .selectedSiteSettingsRefreshed)
            .map { [weak self] _ -> POSEligibilityState in
                guard let self else { return .ineligible(reason: .selfDeallocated) }
                return isEligibleFromSiteSettingsChecks()
            }
            .eraseToAnyPublisher()
    }

    func isEligibleFromSiteSettingsChecks() -> POSEligibilityState {
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
}

private extension POSTabEligibilityChecker {
    enum FeatureFlagState {
        case enabled
        case disabled(reason: POSIneligibleReason)
    }

    var isPointOfSaleFeatureFlagEnabled: AnyPublisher<FeatureFlagState, Never> {
        // Only whitelisted accounts in WPCOM have the Point of Sale remote feature flag enabled. These can be found at D159901-code
        // If the account is whitelisted, then the remote value takes preference over the local feature flag configuration
        Future<FeatureFlagState, Never> { [weak self] promise in
            guard let self else {
                promise(.success(.disabled(reason: .featureFlagDisabled)))
                return
            }
            let action = FeatureFlagAction.isRemoteFeatureFlagEnabled(.pointOfSale, defaultValue: false, completion: { result in
                switch result {
                case true:
                    // The site is whitelisted
                    return promise(.success(.enabled))
                case false:
                    // When the site is not whitelisted, check the local feature flag configuration
                    let localFeatureFlag = self.featureFlagService.isFeatureFlagEnabled(.pointOfSale)
                    return promise(.success(localFeatureFlag ? .enabled : .disabled(reason: .featureFlagDisabled)))
                }
            })
            self.stores.dispatch(action)
        }
        .eraseToAnyPublisher()
    }
}

private extension POSTabEligibilityChecker {
    enum Constants {
        static let wcPluginName = "WooCommerce"
        static let wcPluginMinimumVersion = "9.6.0-beta"
        static let wcPluginMinimumVersionWithFeatureSwitch = "10.0.0"
    }
}
