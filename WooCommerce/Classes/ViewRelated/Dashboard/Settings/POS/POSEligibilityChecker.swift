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

protocol POSEligibilityCheckerProtocol {
    /// As POS eligibility can change from site settings and card payment onboarding state, it's recommended to observe the eligibility value.
    var isEligible: AnyPublisher<Bool, Never> { get }
}

/// Determines whether the POS entry point can be shown based on the selected store and feature gates.
final class POSEligibilityChecker: POSEligibilityCheckerProtocol {
    var isEligible: AnyPublisher<Bool, Never> {
        // Conditions that are fixed for its lifetime.
        let isTablet = userInterfaceIdiom == .pad
        guard isTablet,
              #available(iOS 17.0, *) else {
            return Just(false)
                .eraseToAnyPublisher()
        }

        return Publishers.CombineLatest(isWooCommerceVersionSupportedAndFeatureSwitchEnabled, isPointOfSaleFeatureFlagEnabled)
            .filter { [weak self] _ in
                self?.isEligibleFromSiteChecks ?? false
            }
            .map { $0 && $1 }
            .eraseToAnyPublisher()
    }

    private let userInterfaceIdiom: UIUserInterfaceIdiom
    private let siteSettings: SelectedSiteSettings
    private let currencySettings: CurrencySettings
    private let stores: StoresManager
    private let featureFlagService: FeatureFlagService

    init(userInterfaceIdiom: UIUserInterfaceIdiom = UIDevice.current.userInterfaceIdiom,
         siteSettings: SelectedSiteSettings = ServiceLocator.selectedSiteSettings,
         currencySettings: CurrencySettings = ServiceLocator.currencySettings,
         stores: StoresManager = ServiceLocator.stores,
         featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService) {
        self.userInterfaceIdiom = userInterfaceIdiom
        self.siteSettings = siteSettings
        self.currencySettings = currencySettings
        self.stores = stores
        self.featureFlagService = featureFlagService
    }
}

private extension POSEligibilityChecker {
    var isWooCommerceVersionSupportedAndFeatureSwitchEnabled: AnyPublisher<Bool, Never> {
        Future<Bool, Never> { [weak self] promise in
            guard let self else {
                promise(.success(false))
                return
            }

            guard let siteID = stores.sessionManager.defaultStoreID else {
                DDLogError("⛔️ Default store ID value is nil")
                promise(.success(false))
                return
            }

            let wcPluginMinimumVersion = Constants.wcPluginMinimumVersion

            let action = SystemStatusAction.fetchSystemPlugin(siteID: siteID, systemPluginName: Constants.wcPluginName) { [weak self] wcPlugin in
                guard let self else {
                    return promise(.success(false))
                }
                guard let wcPlugin = wcPlugin, wcPlugin.active else {
                    return promise(.success(false))
                }

                let isSupported = VersionHelpers.isVersionSupported(version: wcPlugin.version,
                                                                    minimumRequired: wcPluginMinimumVersion)

                guard isSupported else {
                    return promise(.success(false))
                }

                // Checks if POS feature is enabled in store settings.
                // The POS feature switch in core is available from version 10.0.0.
                // For core versions below 10.0.0, the feature is enabled by default.
                let isFeatureSwitchSupported = VersionHelpers.isVersionSupported(version: wcPlugin.version,
                                                                                 minimumRequired: Constants.wcPluginMinimumVersionWithFeatureSwitch,
                                                                                 includesDevAndBetaVersions: true)


                guard isFeatureSwitchSupported else {
                    return promise(.success(true))
                }

                let featureAction = SettingAction.isFeatureEnabled(siteID: siteID, feature: .pointOfSale) { result in
                    switch result {
                    case .success(let isEnabled):
                        promise(.success(isEnabled))
                    case .failure:
                        promise(.success(false))
                    }
                }
                self.stores.dispatch(featureAction)
            }
            self.stores.dispatch(action)
        }
        .eraseToAnyPublisher()
    }

    var isPointOfSaleFeatureFlagEnabled: AnyPublisher<Bool, Never> {
        // Only whitelisted accounts in WPCOM have the Point of Sale remote feature flag enabled. These can be found at D159901-code
        // If the account is whitelisted, then the remote value takes preference over the local feature flag configuration
        Future<Bool, Never> { [weak self] promise in
            guard let self else {
                promise(.success(false))
                return
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
