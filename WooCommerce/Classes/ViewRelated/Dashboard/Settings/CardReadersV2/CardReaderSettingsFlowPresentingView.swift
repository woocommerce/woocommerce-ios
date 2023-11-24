import SwiftUI
import Yosemite

/// This wrapper exists to ensure that the `CardReaderSettingsViewModelsOrderedList` has the same lifecycle as the
/// view which presents it. If it doesn't, it's likely that the view model will cause unwanted disconnections
/// from Tap to Pay when it's connected in other parts of the app.
struct CardReaderSettingsFlowPresentingView: View {
    let configuration: CardPresentPaymentsConfiguration
    let siteID: Int64

    var body: some View {
        PaymentSettingsFlowPresentingView(
            viewModelsAndViews: CardReaderSettingsViewModelsOrderedList(
                configuration: configuration,
                siteID: siteID)
        )
    }
}

struct CardReaderSettingsFlowPresentingView_Previews: PreviewProvider {
    static var previews: some View {
        CardReaderSettingsFlowPresentingView(configuration: .init(country: .US),
                                             siteID: 12345)
    }
}
