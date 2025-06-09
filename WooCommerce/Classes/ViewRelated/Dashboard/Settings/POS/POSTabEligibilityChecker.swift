import Combine
import Foundation
import UIKit
import class WooFoundation.CurrencySettings
import enum WooFoundation.CountryCode
import protocol Experiments.FeatureFlagService
import struct Yosemite.SiteSetting
import protocol Yosemite.StoresManager
import struct Yosemite.SiteInformation
import struct Yosemite.SystemPlugin
import enum Yosemite.SystemStatusAction
import enum Yosemite.FeatureFlagAction
import enum Yosemite.SiteSettingsFeature
import enum Yosemite.SettingAction
import enum WooFoundation.CountryCode
import enum WooFoundation.CurrencyCode

enum POSIneligibleReason: Equatable {
    case notTablet
    case unsupportedIOSVersion
    case unsupportedWooCommerceVersion
    case systemInformationNotAvailable
    case wooCommercePluginNotFound
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
    var isEligible: AnyPublisher<POSEligibilityState, Never> { get }
    func refreshEligibility() async throws -> AnyPublisher<POSEligibilityState, Never>
}

protocol POSTabEligibilityCheckerProtocol {
    var isTabVisible: AnyPublisher<Bool, Never> { get }
}

/// Determines whether the POS entry point can be shown based on the selected store and feature gates.
final class POSTabEligibilityChecker: POSTabEligibilityCheckerProtocol, POSEntryPointEligibilityCheckerProtocol {
    @MainActor
    func refreshEligibility() async throws -> AnyPublisher<POSEligibilityState, Never> {
        try await withCheckedThrowingContinuation { continuation in
            stores.dispatch(
                SystemStatusAction.fetchSystemInformationForPOSEligibility(siteID: siteID) { [weak self] result in
                    guard let self else {
                        return continuation.resume(returning: Just(.ineligible(reason: .selfDeallocated)).eraseToAnyPublisher())
                    }
                    switch result {
                    case let .success(systemInformation):
                        // TODO-jc: cache this in memory since system_status request does not update site settings in storage
                        let countryCode = SiteAddress(siteSettings: siteSettings.siteSettings).countryCode
                        switch isEligibleFromCountryAndCurrencyCode(countryCode: countryCode, currencyCode: systemInformation.currencyCode) {
                        case .eligible:
                            break
                        case .ineligible(let reason):
                            return continuation.resume(returning: Just(.ineligible(reason: reason)).eraseToAnyPublisher())
                        }
                        let eligibilityState = isEligibleFromPluginChecks(
                            systemPlugins: systemInformation.activePlugins,
                            enabledFeatures: systemInformation.enabledFeatures
                        )
                        continuation.resume(returning: Just(eligibilityState).eraseToAnyPublisher())
                    case let .failure(error):
                        continuation.resume(throwing: error)
                    }
                })
        }
    }

    var isTabVisible: AnyPublisher<Bool, Never> {
        let isTablet = userInterfaceIdiom == .pad
        guard isTablet else {
            return Just(false)
                .eraseToAnyPublisher()
        }

        return Publishers.CombineLatest(
            isPointOfSaleFeatureFlagEnabled,
            siteSettingsCountryEligibilityPublisher
        )
        .map { featureFlagState, isCountryEligible -> Bool in
            return isCountryEligible && featureFlagState
        }
        .eraseToAnyPublisher()
    }

    var isEligible: AnyPublisher<POSEligibilityState, Never> {
        guard #available(iOS 17.0, *) else {
            return Just(.ineligible(reason: .unsupportedIOSVersion))
                .eraseToAnyPublisher()
        }

        return siteEligibilityPublisher
            .map { [weak self] siteEligibility -> POSEligibilityState in
                guard let self else { return .ineligible(reason: .selfDeallocated) }
                switch isEligibleFromSiteSettingsChecks() {
                case .eligible:
                    break
                case .ineligible(let reason):
                    return .ineligible(reason: reason)
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

        switch isEligibleFromCountryAndCurrencyCode(countryCode: countryCode, currencyCode: currency) {
        case .eligible:
            break
        case .ineligible(let reason):
            return .ineligible(reason: reason)
        }

        guard let siteInformation, siteInformation.siteID == siteID else {
            return .ineligible(reason: .systemInformationNotAvailable)
        }

        return isEligibleFromPluginChecks(systemPlugins: siteInformation.systemInformation?.systemPlugins ?? [],
                                          enabledFeatures: siteInformation.systemInformation?.enabledFeatures)
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
    var siteSettingsCountryEligibilityPublisher: AnyPublisher<Bool, Never> {
        NotificationCenter.default.publisher(for: .selectedSiteSettingsRefreshed, object: siteSettings)
            .map { [weak self] _ -> Bool in
                guard let self else { return false }
                // Conditions that can change if site settings are synced during the lifetime.
                let countryCode = SiteAddress(siteSettings: siteSettings.siteSettings).countryCode

                // Checks country first.
                switch countryCode {
                case .US, .GB:
                    return true
                default:
                    return false
                }
            }
            .eraseToAnyPublisher()
    }
}

private extension POSTabEligibilityChecker {
    var siteSettingsEligibilityPublisher: AnyPublisher<POSEligibilityState, Never> {
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
    var isPointOfSaleFeatureFlagEnabled: AnyPublisher<Bool, Never> {
        // Only whitelisted accounts in WPCOM have the Point of Sale remote feature flag enabled. These can be found at D159901-code
        // If the account is whitelisted, then the remote value takes preference over the local feature flag configuration
        Future<Bool, Never> { [weak self] promise in
            guard let self else {
                return promise(.success(false))
            }
            let action = FeatureFlagAction.isRemoteFeatureFlagEnabled(.pointOfSale, defaultValue: false, completion: { result in
                switch result {
                case true:
                    // The site is whitelisted
                    return promise(.success(true))
                case false:
                    // When the site is not whitelisted, check the local feature flag configuration
                    let localFeatureFlag = self.featureFlagService.isFeatureFlagEnabled(.pointOfSale)
                    return promise(.success(localFeatureFlag))
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
