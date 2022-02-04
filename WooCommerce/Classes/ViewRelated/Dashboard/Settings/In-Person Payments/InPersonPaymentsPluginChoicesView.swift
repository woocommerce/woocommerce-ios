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
        VStack {
            Text(CardPresentPaymentsPlugins.wcPay.pluginName)
                .font(.callout)
                .bold()
                .padding(.bottom, 1)
            Text(Localization.conjunctiveOr)
                .font(.callout)
                .padding(.bottom, 1)
            Text(CardPresentPaymentsPlugins.stripe.pluginName)
                .font(.callout).bold()
                .padding(.bottom, isCompact ? 12 : 24)
        }
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
