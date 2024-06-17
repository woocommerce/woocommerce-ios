import SwiftUI
import protocol Experiments.FeatureFlagService
import struct Storage.GeneralAppSettingsStorage

@MainActor
final class BetaFeaturesConfigurationViewModel: ObservableObject {
    @Published private(set) var availableFeatures: [BetaFeature] = []
    private let appSettings: GeneralAppSettingsStorage
    private let featureFlagService: FeatureFlagService
    private let posEligibilityChecker: POSEligibilityCheckerProtocol

    init(appSettings: GeneralAppSettingsStorage = ServiceLocator.generalAppSettings,
         featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService,
         posEligibilityChecker: POSEligibilityCheckerProtocol? = nil) {
        self.appSettings = appSettings
        self.featureFlagService = featureFlagService
        self.posEligibilityChecker = posEligibilityChecker ?? POSEligibilityChecker(
            cardPresentPaymentsOnboarding: CardPresentPaymentsOnboardingUseCase(),
            siteSettings: ServiceLocator.selectedSiteSettings,
            currencySettings: ServiceLocator.currencySettings,
            featureFlagService: ServiceLocator.featureFlagService
         )
        observePOSEligibilityForAvailableFeatures()
    }

    func isOn(feature: BetaFeature) -> Binding<Bool> {
        appSettings.betaFeatureEnabledBinding(feature)
    }
}

private extension BetaFeaturesConfigurationViewModel {
    @MainActor
    func observePOSEligibilityForAvailableFeatures() {
        posEligibilityChecker.isEligible
            .map { [weak self] isEligibleForPOS in
                guard let self else {
                    return []
                }
                return BetaFeature.allCases.filter { betaFeature in
                    switch betaFeature {
                        case .viewAddOns:
                            return true
                        case .inAppPurchases:
                            return self.featureFlagService.isFeatureFlagEnabled(.inAppPurchasesDebugMenu)
                        case .pointOfSale:
                            return isEligibleForPOS
                    }
                }
            }
            .assign(to: &$availableFeatures)
    }
}
