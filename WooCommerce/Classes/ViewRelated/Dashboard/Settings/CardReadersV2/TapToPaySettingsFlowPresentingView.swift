import SwiftUI
import Yosemite


/// This wrapper exists to ensure that the `SetUpTapToPayViewModelsOrderedList` has the same lifecycle as the
/// view which presents it. If it doesn't, it's likely that the view model will cause unwanted disconnections
/// from Bluetooth readers which are connected in other parts of the app.
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
