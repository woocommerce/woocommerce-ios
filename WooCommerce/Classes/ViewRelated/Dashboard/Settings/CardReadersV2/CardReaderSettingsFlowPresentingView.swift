import SwiftUI
import Yosemite

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
