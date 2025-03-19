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

protocol POSEligibilityCheckerProtocol {
    /// As POS eligibility can change from site settings and card payment onboarding state, it's recommended to observe the eligibility value.
    var isEligible: AnyPublisher<Bool, Never> { get }
    /// Experiment: Specific mercants that operate outside eligible markets may only have QR Scan to Pay enabled
    var isOnlyScanToPayEnabled: Bool { get }
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

        return Publishers.CombineLatest3(isWooCommerceVersionSupported, isPointOfSaleFeatureFlagEnabled, isPointOfSaleOnlyScanToPayEnabled)
            .filter { [weak self] _ in
                self?.isEligibleFromSiteChecks ?? false
            }
            .map { $0 && ($1 || $2) }
            .eraseToAnyPublisher()
    }

    private let userInterfaceIdiom: UIUserInterfaceIdiom
    private let siteSettings: SelectedSiteSettings
    private let currencySettings: CurrencySettings
    private let stores: StoresManager
    private let featureFlagService: FeatureFlagService
    var isOnlyScanToPayEnabled: Bool = false

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
    var isWooCommerceVersionSupported: AnyPublisher<Bool, Never> {
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

            let action = SystemStatusAction.fetchSystemPlugin(siteID: siteID, systemPluginName: Constants.wcPluginName) { wcPlugin in
                guard let wcPlugin = wcPlugin, wcPlugin.active else {
                    promise(.success(false))
                    return
                }

                let isSupported = VersionHelpers.isVersionSupported(version: wcPlugin.version,
                                                                    minimumRequired: wcPluginMinimumVersion)
                promise(.success(isSupported))
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
    var isPointOfSaleOnlyScanToPayEnabled: AnyPublisher<Bool, Never> {
        // Experimental feature
        // Only whitelisted accounts in WPCOM have the woo_pos_only_scan_to_pay remote feature flag enabled. These can be found at D159901-code
        Future<Bool, Never> { [weak self] promise in
            guard let self else {
                promise(.success(false))
                return
            }
            let action = FeatureFlagAction.isRemoteFeatureFlagEnabled(.pointOfSaleOnlyScanToPay, defaultValue: false, completion: { [weak self] result in
                self?.isOnlyScanToPayEnabled = result
                return promise(.success(result))
            })
            self.stores.dispatch(action)
        }
        .eraseToAnyPublisher()
    }

}

private extension POSEligibilityChecker {
    enum Constants {
        static let wcPluginName = "WooCommerce"
        static let wcPluginMinimumVersion = "9.6.0-beta"
    }
}
