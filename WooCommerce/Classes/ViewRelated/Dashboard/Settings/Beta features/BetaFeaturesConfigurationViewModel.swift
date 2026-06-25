import SwiftUI
import protocol Experiments.FeatureFlagService
import struct Storage.GeneralAppSettingsStorage

final class BetaFeaturesConfigurationViewModel: ObservableObject {
    @Published private(set) var availableFeatures: [BetaFeature] = []
    private let appSettings: GeneralAppSettingsStorage
    private let featureFlagService: FeatureFlagService
    private let isPOSTabVisible: () async -> Bool

    private let betaFeatures = BetaFeature.allCases

    private let appPasswordsExperimentAvailabilityChecker: ApplicationPasswordsExperimentAvailabilityCheckerProtocol

    init(appSettings: GeneralAppSettingsStorage = ServiceLocator.generalAppSettings,
         featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService,
         isPOSTabVisible: @escaping () async -> Bool = BetaFeaturesConfigurationViewModel.defaultPOSTabVisibility) {
        self.appSettings = appSettings
        self.featureFlagService = featureFlagService
        self.isPOSTabVisible = isPOSTabVisible
        self.appPasswordsExperimentAvailabilityChecker = ApplicationPasswordsExperimentAvailabilityChecker()

        setupInitialFeaturesVisibility()
        updateFeaturesAvailability()
    }

    func isOn(feature: BetaFeature) -> Binding<Bool> {
        appSettings.betaFeatureEnabledBinding(feature)
    }

    func refreshAvailableFeatures() async {
        let fetchedAvailableFeatures = await fetchFeaturesAvailability()

        await MainActor.run {
            availableFeatures = fetchedAvailableFeatures
        }
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
                return false
        }
    }

    func setupInitialFeaturesVisibility() {
        availableFeatures = betaFeatures.filter { betaFeature in
            isVisible(feature: betaFeature)
        }
    }

    func updateFeaturesAvailability() {
        Task {
            await refreshAvailableFeatures()
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
                if await shouldShowPOSLocalCatalog() {
                    results.append(feature)
                }
            }
        }

        return results
    }

    func shouldShowPOSLocalCatalog() async -> Bool {
        guard featureFlagService.isFeatureFlagEnabled(.pointOfSaleCatalogAPI) else {
            return false
        }
        return await isPOSTabVisible()
    }
}

extension BetaFeaturesConfigurationViewModel {
    static func defaultPOSTabVisibility() async -> Bool {
        guard let site = ServiceLocator.stores.sessionManager.defaultSite else {
            return false
        }
        return await POSTabVisibilityChecker(site: site).checkVisibility()
    }
}
