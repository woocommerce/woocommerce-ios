import SwiftUI
import Yosemite

struct PluginDetailsRowView: View {
    let viewModel: PluginDetailsViewModel

    @State var webViewPresented = false

    var body: some View {
        NavigationRow(selectable: viewModel.updateURL != nil,
                      content: {
            PluginDetailsRowContent(viewModel: viewModel)
                .sheet(isPresented: $webViewPresented,
                       onDismiss: {
                    viewModel.refreshPlugin()
                }) {
                    if let updateURL = viewModel.updateURL {
                        SafariView(url: updateURL)
                    }
                }
        },
                      action: { webViewPresented.toggle() })
    }
}

struct PluginDetailsRowContent: View {
    let viewModel: PluginDetailsViewModel

    var body: some View {
        HStack {
            VStack {
                HStack {
                    Text(viewModel.title)
                        .bodyStyle()
                    Spacer()
                    Text(viewModel.version)
                        .secondaryBodyStyle()
                }
                if viewModel.updateURL != nil {
                    PluginDetailsRowUpdateAvailable(versionLatest: viewModel.versionLatest)
                    .padding([.top], 2)
                }
            }
        }
    }

}

struct PluginDetailsRowUpdateAvailable: View {
    @State var versionLatest: String?

    var body: some View {
        HStack {
            Image(systemName: Constants.softwareUpdateSymbolName)
            Text(Localization.updateAvailableTitle)
            Spacer()
            if let versionLatest = versionLatest {
                Text(versionLatest)
            }
        }
        .font(.footnote)
        .foregroundColor(Color(.warning))
    }
}

private enum Constants {
    static let softwareUpdateSymbolName = "exclamationmark.arrow.triangle.2.circlepath"
}

private enum Localization {
    static let updateAvailableTitle = NSLocalizedString(
        "Latest version",
        comment: "String shown to indicate the latest version of a plugin when an " +
        "update is available and highlighted to the user")
}

struct PluginDetailsRowView_Previews: PreviewProvider {
    static var previews: some View {
        PluginDetailsRowView(viewModel: PreviewsPluginDetailsRowViewModel())
            .previewLayout(.fixed(width: 375, height: 100))
    }
}

private struct PreviewsPluginDetailsRowViewModel: PluginDetailsViewModel {
    var updateURL: URL? = URL(string: "https://woocommerce.com/plugins/update")!

    var title = "WooCommerce Version"

    var version = "5.9.0"

    var versionLatest: String? = "6.9.0"

    func refreshPlugin() {
        // no-op
    }
}
