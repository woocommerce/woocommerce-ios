import SwiftUI
import Yosemite

struct InPersonPaymentsPluginChoicesView: View {
    @Environment(\.verticalSizeClass) var verticalSizeClass

    var isCompact: Bool {
        get {
            verticalSizeClass == .compact
        }
    }

    var body: some View {
        Text(CardPresentPaymentsPlugins.wcPay.pluginName)
            .font(.callout)
        Text(Localization.conjunctiveOr)
            .font(.body)
        Text(CardPresentPaymentsPlugins.stripe.pluginName)
            .font(.callout)
            .padding(.bottom, isCompact ? 12 : 24)
    }
}

private enum Localization {
    static let conjunctiveOr = NSLocalizedString(
        "or",
        comment: "A single word displayed on a line by itself inbetween the names of two plugins"
    )
}

struct InPersonPaymentsPluginChoicesView_Previews: PreviewProvider {
    static var previews: some View {
        InPersonPaymentsPluginChoicesView()
    }
}
