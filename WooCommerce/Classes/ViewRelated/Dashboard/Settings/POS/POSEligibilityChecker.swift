import Combine
import Foundation
import UIKit
import class WooFoundation.CurrencySettings
import enum WooFoundation.CountryCode
import protocol Experiments.FeatureFlagService
import struct Yosemite.SiteSetting

/// Determines whether the POS entry point can be shown based on the selected store and feature gates.
final class POSEligibilityChecker {
    @Published private(set) var isEligible: Bool = false
    private var onboardingStateSubscription: AnyCancellable?

    private let cardPresentPaymentsOnboarding: CardPresentPaymentsOnboardingUseCaseProtocol
    private let siteSettings: SelectedSiteSettings
    private let currencySettings: CurrencySettings
    private let featureFlagService: FeatureFlagService

    init(cardPresentPaymentsOnboarding: CardPresentPaymentsOnboardingUseCaseProtocol = CardPresentPaymentsOnboardingUseCase(),
         siteSettings: SelectedSiteSettings = ServiceLocator.selectedSiteSettings,
         currencySettings: CurrencySettings = ServiceLocator.currencySettings,
         featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService) {
        self.siteSettings = siteSettings
        self.currencySettings = currencySettings
        self.cardPresentPaymentsOnboarding = cardPresentPaymentsOnboarding
        self.featureFlagService = featureFlagService
        observeOnboardingStateForEligibilityCheck()
    }
}

private extension POSEligibilityChecker {
    /// Returns whether the selected store is eligible for POS.
    func observeOnboardingStateForEligibilityCheck() {
        // Conditions that are fixed per lifetime of the menu tab.
        let isTablet = UIDevice.current.userInterfaceIdiom == .pad
        let isFeatureFlagEnabled = featureFlagService.isFeatureFlagEnabled(.displayPointOfSaleToggle)
        guard isTablet && isFeatureFlagEnabled else {
            isEligible = false
            return
        }

        cardPresentPaymentsOnboarding.statePublisher
            .filter { [weak self] _ in
                self?.isEligibleFromSiteChecks() ?? false
            }
            .map { onboardingState in
                // Woo Payments plugin enabled and user setup complete
                onboardingState == .completed(plugin: .wcPayOnly) || onboardingState == .completed(plugin: .wcPayPreferred)
            }
            .assign(to: &$isEligible)
    }

    func isEligibleFromSiteChecks() -> Bool {
        // Conditions that can change if site settings are synced during the lifetime of the menu tab.
        let isCountryCodeUS = SiteAddress(siteSettings: siteSettings.siteSettings).countryCode == .US
        let isCurrencyUSD = currencySettings.currencyCode == .USD
        return isCountryCodeUS && isCurrencyUSD
    }
}
