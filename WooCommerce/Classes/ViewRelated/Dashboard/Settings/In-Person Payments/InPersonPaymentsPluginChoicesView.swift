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
            ForEach(CardPresentPaymentsPlugins.allCases, id: \.self) { plugin in
                Text(plugin.pluginName)
                    .font(.callout)
                    .bold()
                    .padding(.bottom, 1)
            }
        }.padding(.bottom, isCompact ? 12 : 24)
    }
}

struct InPersonPaymentsPluginChoicesView_Previews: PreviewProvider {
    static var previews: some View {
        InPersonPaymentsPluginChoicesView()
    }
}
