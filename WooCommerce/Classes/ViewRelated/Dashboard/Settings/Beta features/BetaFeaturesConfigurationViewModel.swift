import SwiftUI
import UIKit
import protocol Experiments.FeatureFlagService
import struct Storage.GeneralAppSettingsStorage

final class BetaFeaturesConfigurationViewModel: ObservableObject {
    @Published private(set) var availableFeatures: [BetaFeature] = []
    private let appSettings: GeneralAppSettingsStorage
    private let featureFlagService: FeatureFlagService
    private let isIPad: Bool

    private let betaFeatures = BetaFeature.allCases

    private let appPasswordsExperimentAvailabilityChecker: ApplicationPasswordsExperimentAvailabilityCheckerProtocol

    init(appSettings: GeneralAppSettingsStorage = ServiceLocator.generalAppSettings,
         featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService,
         isIPad: Bool = UIDevice.current.userInterfaceIdiom == .pad) {
        self.appSettings = appSettings
        self.featureFlagService = featureFlagService
        self.isIPad = isIPad
        self.appPasswordsExperimentAvailabilityChecker = ApplicationPasswordsExperimentAvailabilityChecker()

        setupInitialFeaturesVisibility()
        updateFeaturesAvailability()
    }

    func isOn(feature: BetaFeature) -> Binding<Bool> {
        appSettings.betaFeatureEnabledBinding(feature)
    }
}

private extension BetaFeaturesConfigurationViewModel {
    func isVisible(feature: BetaFeature) -> Bool {
        switch feature {
            case .viewAddOns:
                return true
            case .applicationPasswords:
                return appPasswordsExperimentAvailabilityChecker.isAvailable
            case .posLocalCatalog:
                return isIPad && featureFlagService.isFeatureFlagEnabled(.pointOfSaleCatalogAPI)
        }
    }

    func setupInitialFeaturesVisibility() {
        availableFeatures = betaFeatures.filter { betaFeature in
            isVisible(feature: betaFeature)
        }
    }

    func updateFeaturesAvailability() {
        Task {
            let fetchedAvailableFeatures = await fetchFeaturesAvailability()

            await MainActor.run {
                availableFeatures = fetchedAvailableFeatures
            }
        }
    }

    func fetchFeaturesAvailability() async -> [BetaFeature] {
        var results = [BetaFeature]()
        for feature in betaFeatures {
            switch feature {
            case .viewAddOns:
                results.append(feature)
            case .applicationPasswords:
                if await appPasswordsExperimentAvailabilityChecker.fetchAvailability() {
                    results.append(feature)
                }
            case .posLocalCatalog:
                if isIPad && featureFlagService.isFeatureFlagEnabled(.pointOfSaleCatalogAPI) {
                    results.append(feature)
                }
            }
        }

        return results
    }
}
