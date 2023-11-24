import SwiftUI
import Yosemite

struct TapToPaySettingsFlowPresentingView: View {
    let configuration: CardPresentPaymentsConfiguration
    let siteID: Int64
    let onboardingUseCase: CardPresentPaymentsOnboardingUseCaseProtocol

    var body: some View {
        PaymentSettingsFlowPresentingView(
            viewModelsAndViews: SetUpTapToPayViewModelsOrderedList(
                siteID: siteID,
                configuration: configuration,
                onboardingUseCase: onboardingUseCase)
            )
    }
}

struct TapToPaySettingsFlowPresentingView_Previews: PreviewProvider {
    static var previews: some View {
        TapToPaySettingsFlowPresentingView(configuration: .init(country: .US),
                                           siteID: 12345,
                                           onboardingUseCase: CardPresentPaymentsOnboardingUseCase())
    }
}
