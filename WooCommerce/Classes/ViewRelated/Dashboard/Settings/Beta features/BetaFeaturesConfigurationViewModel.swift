import SwiftUI
import protocol Experiments.FeatureFlagService
import struct Storage.GeneralAppSettingsStorage

final class BetaFeaturesConfigurationViewModel: ObservableObject {
    @Published private(set) var availableFeatures: [BetaFeature] = []
    private let appSettings: GeneralAppSettingsStorage
    private let featureFlagService: FeatureFlagService

    init(appSettings: GeneralAppSettingsStorage = ServiceLocator.generalAppSettings,
         featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService) {
        self.appSettings = appSettings
        self.featureFlagService = featureFlagService
        availableFeatures = BetaFeature.allCases.filter { betaFeature in
            switch betaFeature {
                case .viewAddOns:
                    return true
            }
        }
    }

    func isOn(feature: BetaFeature) -> Binding<Bool> {
        appSettings.betaFeatureEnabledBinding(feature)
    }
}
