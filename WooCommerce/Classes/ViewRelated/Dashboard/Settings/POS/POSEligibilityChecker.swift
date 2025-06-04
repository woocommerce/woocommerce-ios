import Combine
import Foundation
import UIKit
import class WooFoundation.CurrencySettings
import enum WooFoundation.CountryCode
import protocol Experiments.FeatureFlagService
import struct Yosemite.SiteSetting
import protocol Yosemite.StoresManager
import enum Yosemite.SystemStatusAction
import enum Yosemite.FeatureFlagAction
import enum Yosemite.SettingAction

enum POSIneligibleReason: Equatable {
    case notTablet
    case unsupportedIOSVersion
    case unsupportedWooCommerceVersion
    case featureSwitchSyncFailure
    case featureFlagDisabled
    case unsupportedCountryOrCurrency
}

enum POSEligibilityState: Equatable {
    case eligible
    case ineligible(reason: POSIneligibleReason)
}

protocol POSEligibilityCheckerProtocol {
    /// As POS eligibility can change from site settings and card payment onboarding state, it's recommended to observe the eligibility value.
    var isEligible: AnyPublisher<POSEligibilityState, Never> { get }
}

/// Determines whether the POS entry point can be shown based on the selected store and feature gates.
final class POSEligibilityChecker: POSEligibilityCheckerProtocol {
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

        return Publishers.CombineLatest(isWooCommerceVersionSupportedAndFeatureSwitchEnabled, isPointOfSaleFeatureFlagEnabled)
            .map { [weak self] wooCommerceState, featureFlagState -> POSEligibilityState in
                guard let self else {
                    return .ineligible(reason: .unsupportedWooCommerceVersion)
                }

                if !isEligibleFromSiteChecks {
                    return .ineligible(reason: .unsupportedCountryOrCurrency)
                }

                switch wooCommerceState {
                case .unsupported(let reason):
                    return .ineligible(reason: reason)
                case .supported:
                    switch featureFlagState {
                    case .disabled(let reason):
                        return .ineligible(reason: reason)
                    case .enabled:
                        return .eligible
                    }
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

private extension POSEligibilityChecker {
    enum WooCommerceVersionSupportState {
        case supported
        case unsupported(reason: POSIneligibleReason)
    }

    enum FeatureFlagState {
        case enabled
        case disabled(reason: POSIneligibleReason)
    }

    var isWooCommerceVersionSupported: AnyPublisher<(isSupported: Bool, wcVersion: String?), Never> {
        Future<(isSupported: Bool, wcVersion: String?), Never> { [weak self] promise in
            guard let self else {
                promise(.success((isSupported: false, wcVersion: nil)))
                return
            }

            let wcPluginMinimumVersion = Constants.wcPluginMinimumVersion

            let action = SystemStatusAction.fetchSystemPlugin(siteID: siteID, systemPluginName: Constants.wcPluginName) { wcPlugin in
                guard let wcPlugin, wcPlugin.active else {
                    return promise(.success((isSupported: false, wcVersion: nil)))
                }

                let isSupported = VersionHelpers.isVersionSupported(version: wcPlugin.version,
                                                                    minimumRequired: wcPluginMinimumVersion)
                promise(.success((isSupported: isSupported, wcVersion: wcPlugin.version)))
            }
            self.stores.dispatch(action)
        }
        .eraseToAnyPublisher()
    }

    var isWooCommerceVersionSupportedAndFeatureSwitchEnabled: AnyPublisher<WooCommerceVersionSupportState, Never> {
        isWooCommerceVersionSupported
            .flatMap { [weak self] isSupported, wcVersion -> AnyPublisher<WooCommerceVersionSupportState, Never> in
                guard let self,
                      isSupported,
                      let wcVersion else {
                    return Just(.unsupported(reason: .unsupportedWooCommerceVersion))
                        .eraseToAnyPublisher()
                }

                // For versions below 10.0.0, the feature is enabled by default.
                let isFeatureSwitchSupported = VersionHelpers.isVersionSupported(version: wcVersion,
                                                                                 minimumRequired: Constants.wcPluginMinimumVersionWithFeatureSwitch,
                                                                                 includesDevAndBetaVersions: true)
                if !isFeatureSwitchSupported {
                    return Just(.supported)
                        .eraseToAnyPublisher()
                }

                // For versions that support the feature switch, checks if the feature switch is enabled.
                return Future<WooCommerceVersionSupportState, Never> { promise in
                    let action = SettingAction.isFeatureEnabled(siteID: self.siteID, feature: .pointOfSale) { result in
                        switch result {
                        case .success(let isEnabled):
                            promise(.success(isEnabled ? .supported : .unsupported(reason: .featureSwitchSyncFailure)))
                        case .failure:
                            promise(.success(.unsupported(reason: .featureSwitchSyncFailure)))
                        }
                    }
                    self.stores.dispatch(action)
                }
                .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
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

    var isEligibleFromSiteChecks: Bool {
        // Conditions that can change if site settings are synced during the lifetime.
        let countryCode = SiteAddress(siteSettings: siteSettings.siteSettings).countryCode
        let currency = currencySettings.currencyCode
        switch (countryCode, currency) {
            case (.US, .USD),
                (.GB, .GBP):
                return true
            default:
                return false
        }
    }
}

private extension POSEligibilityChecker {
    enum Constants {
        static let wcPluginName = "WooCommerce"
        static let wcPluginMinimumVersion = "9.6.0-beta"
        static let wcPluginMinimumVersionWithFeatureSwitch = "10.0.0"
    }
}
