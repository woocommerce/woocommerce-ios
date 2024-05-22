import SwiftUI
import Yosemite
import protocol Experiments.FeatureFlagService
import struct Storage.GeneralAppSettingsStorage

final class BetaFeaturesConfigurationViewController: UIHostingController<BetaFeaturesConfiguration> {

    init() {
        super.init(rootView: BetaFeaturesConfiguration(viewModel: .init()))
    }

    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class BetaFeaturesConfigurationViewModel: ObservableObject {
    @Published private(set) var availableFeatures: [BetaFeature] = []
    private let appSettings: GeneralAppSettingsStorage
    private let featureFlagService: FeatureFlagService
    private let posEligibilityChecker: POSEligibilityChecker

    init(appSettings: GeneralAppSettingsStorage = ServiceLocator.generalAppSettings,
         featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService,
         posEligibilityChecker: POSEligibilityChecker = POSEligibilityChecker(cardPresentPaymentsOnboarding: CardPresentPaymentsOnboardingUseCase(),
                                                                              siteSettings: ServiceLocator.selectedSiteSettings,
                                                                              currencySettings: ServiceLocator.currencySettings,
                                                                              featureFlagService: ServiceLocator.featureFlagService)) {
        self.appSettings = appSettings
        self.featureFlagService = featureFlagService
        self.posEligibilityChecker = posEligibilityChecker
        observePOSEligibilityForAvailableFeatures()
    }

    func isOn(feature: BetaFeature) -> Binding<Bool> {
        appSettings.betaFeatureEnabledBinding(feature)
    }
}

private extension BetaFeaturesConfigurationViewModel {
    func observePOSEligibilityForAvailableFeatures() {
        posEligibilityChecker.$isEligible
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

struct BetaFeaturesConfiguration: View {
    @StateObject private var viewModel: BetaFeaturesConfigurationViewModel

    init(viewModel: BetaFeaturesConfigurationViewModel) {
        self._viewModel = .init(wrappedValue: viewModel)
    }

    var body: some View {
        List {
            ForEach(viewModel.availableFeatures) { feature in
                Section(footer: Text(feature.description)) {
                    TitleAndToggleRow(title: feature.title, isOn: viewModel.isOn(feature: feature))
                }
            }
        }
        .background(Color(.listForeground(modal: false)))
        .listStyle(.grouped)
        .navigationTitle(Localization.title)
    }
}

private enum Localization {
    static let title = NSLocalizedString("Experimental Features", comment: "Experimental features navigation title")
}

struct BetaFeaturesConfiguration_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            BetaFeaturesConfiguration(viewModel: .init())
        }
    }
}
