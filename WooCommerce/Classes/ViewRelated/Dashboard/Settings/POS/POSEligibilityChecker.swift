import Combine
import Foundation
import UIKit
import class WooFoundation.CurrencySettings
import enum WooFoundation.CountryCode
import protocol Experiments.FeatureFlagService
import struct Yosemite.SiteSetting
import protocol Yosemite.StoresManager
import enum Yosemite.SystemStatusAction

protocol POSEligibilityCheckerProtocol {
    /// As POS eligibility can change from site settings and card payment onboarding state, it's recommended to observe the eligibility value.
    var isEligible: AnyPublisher<Bool, Never> { get }
}

/// Determines whether the POS entry point can be shown based on the selected store and feature gates.
final class POSEligibilityChecker: POSEligibilityCheckerProtocol {
    var isEligible: AnyPublisher<Bool, Never> {
        // Conditions that are fixed for its lifetime.
        let isTablet = userInterfaceIdiom == .pad
        let isFeatureFlagEnabled = featureFlagService.isFeatureFlagEnabled(.displayPointOfSaleToggle)
        guard isTablet && isFeatureFlagEnabled else {
            return Just(false)
                .eraseToAnyPublisher()
        }

        return Publishers.CombineLatest(isOnboardingComplete, isWooCommerceVersionSupported)
            .map { $0 && $1 }
            .eraseToAnyPublisher()
    }

    private let userInterfaceIdiom: UIUserInterfaceIdiom
    private let cardPresentPaymentsOnboarding: CardPresentPaymentsOnboardingUseCaseProtocol
    private let siteSettings: SelectedSiteSettings
    private let currencySettings: CurrencySettings
    private let stores: StoresManager
    private let featureFlagService: FeatureFlagService

    init(userInterfaceIdiom: UIUserInterfaceIdiom = UIDevice.current.userInterfaceIdiom,
         cardPresentPaymentsOnboarding: CardPresentPaymentsOnboardingUseCaseProtocol = CardPresentPaymentsOnboardingUseCase(),
         siteSettings: SelectedSiteSettings = ServiceLocator.selectedSiteSettings,
         currencySettings: CurrencySettings = ServiceLocator.currencySettings,
         stores: StoresManager = ServiceLocator.stores,
         featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService) {
        self.userInterfaceIdiom = userInterfaceIdiom
        self.siteSettings = siteSettings
        self.currencySettings = currencySettings
        self.cardPresentPaymentsOnboarding = cardPresentPaymentsOnboarding
        self.stores = stores
        self.featureFlagService = featureFlagService
    }
}

private extension POSEligibilityChecker {
    var isOnboardingComplete: AnyPublisher<Bool, Never> {
        return cardPresentPaymentsOnboarding.statePublisher
            .filter { [weak self] _ in
                self?.isEligibleFromSiteChecks ?? false
            }
            .map { onboardingState in
                // Woo Payments plugin enabled and user setup complete
                onboardingState == .completed(plugin: .wcPayOnly) || onboardingState == .completed(plugin: .wcPayPreferred)
            }
            .eraseToAnyPublisher()
    }

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

            let action = SystemStatusAction.fetchSystemPlugin(siteID: siteID, systemPluginName: Constants.wcPluginName) { wcPlugin in
                guard let wcPlugin = wcPlugin, wcPlugin.active else {
                    promise(.success(false))
                    return
                }

                let isSupported = VersionHelpers.isVersionSupported(version: wcPlugin.version,
                                                                    minimumRequired: Constants.wcPluginMinimumVersion)
                promise(.success(isSupported))
            }
            self.stores.dispatch(action)
        }
        .eraseToAnyPublisher()
    }

    var isEligibleFromSiteChecks: Bool {
        // Conditions that can change if site settings are synced during the lifetime.
        let isCountryCodeUS = SiteAddress(siteSettings: siteSettings.siteSettings).countryCode == .US
        let isCurrencyUSD = currencySettings.currencyCode == .USD
        return isCountryCodeUS && isCurrencyUSD
    }
}

private extension POSEligibilityChecker {
    enum Constants {
        static let wcPluginName = "WooCommerce"
        static let wcPluginMinimumVersion = "6.6.0"
    }
}
