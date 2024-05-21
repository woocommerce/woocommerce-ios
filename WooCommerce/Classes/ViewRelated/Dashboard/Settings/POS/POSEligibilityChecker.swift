import Foundation
import UIKit
import class WooFoundation.CurrencySettings
import enum WooFoundation.CountryCode
import protocol Experiments.FeatureFlagService
import struct Yosemite.SiteSetting

/// Determines whether the POS entry point can be shown based on the selected store and feature gates.
final class POSEligibilityChecker {
    private let cardPresentPaymentsOnboarding: CardPresentPaymentsOnboardingUseCaseProtocol
    private let siteSettings: [SiteSetting]
    private let currencySettings: CurrencySettings
    private let featureFlagService: FeatureFlagService

    init(cardPresentPaymentsOnboarding: CardPresentPaymentsOnboardingUseCaseProtocol = CardPresentPaymentsOnboardingUseCase(),
         siteSettings: [SiteSetting] = ServiceLocator.selectedSiteSettings.siteSettings,
         currencySettings: CurrencySettings = ServiceLocator.currencySettings,
         featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService) {
        self.siteSettings = siteSettings
        self.currencySettings = currencySettings
        self.cardPresentPaymentsOnboarding = cardPresentPaymentsOnboarding
        self.featureFlagService = featureFlagService
    }

    /// Returns whether the selected store is eligible for POS.
    func isEligible() -> Bool {
        // Always checks the main POS feature flag before any other checks.
        guard featureFlagService.isFeatureFlagEnabled(.displayPointOfSaleToggle) else {
            return false
        }

        let isCountryCodeUS = SiteAddress(siteSettings: siteSettings).countryCode == CountryCode.US
        let isCurrencyUSD = currencySettings.currencyCode == .USD

        // Tablet device
        return UIDevice.current.userInterfaceIdiom == .pad
        // Woo Payments plugin enabled and user setup complete
        && (cardPresentPaymentsOnboarding.state == .completed(plugin: .wcPayOnly) || cardPresentPaymentsOnboarding.state == .completed(plugin: .wcPayPreferred))
        // USD currency
        && isCurrencyUSD
        // US store location
        && isCountryCodeUS
    }
}
