import SwiftUI
import Yosemite

struct PluginListView: View {
    @ObservedObject var viewModel: PluginListViewModel

    @State private var showModal = false

    var body: some View {
        NavigationRow(selectable: true, content: {
            Text("Plugins")
        }, action: {
            showModal = true
        })
        .sheet(isPresented: $showModal, content: {
            PluginListDetailView(viewModel: viewModel)
        })
    }
}

struct PluginListDetailView: View {

    private let viewModel: PluginListViewModel

    init(viewModel: PluginListViewModel) {
        self.viewModel = viewModel
    }

    @State private var showWebView = false

    var updateUrl: URL? {
        // TODO: Inject from storesManager.sessionManager.defaultSite?.pluginsURL,
        return URL(string: "https://woo.com")!
    }

    var body: some View {
        ScrollView {
            ForEach(viewModel.pluginList(), id: \.self) { plugin in
                let pluginDetailsViewModel = PluginDetailsViewModel(siteID: 215063064,
                                                                    pluginName: plugin.name)
                NavigationRow(content: {
                    PluginDetailsRowContent(viewModel: pluginDetailsViewModel)
                }, action: {
                    print("\(plugin.name) tapped")
                    
                })
            }
        }
    }
}

struct PluginDetailsRowView: View {
    @ObservedObject var viewModel: PluginDetailsViewModel

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
    @ObservedObject var viewModel: PluginDetailsViewModel

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
                .padding([.bottom], 2)

                if viewModel.updateAvailable {
                    PluginDetailsRowUpdateAvailable(versionLatest: viewModel.versionLatest)
                } else {
                    PluginDetailsRowUpToDate()
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

struct PluginDetailsRowUpToDate: View {
    var body: some View {
        HStack {
            Image(systemName: Constants.upToDateSymbolName)
            Text(Localization.upToDateTitle)
            Spacer()
        }
        .font(.footnote)
        .foregroundColor(Color(UIColor.systemGreen))
    }
}

private enum Constants {
    static let softwareUpdateSymbolName = "exclamationmark.arrow.triangle.2.circlepath"
    static let upToDateSymbolName = "checkmark.circle"
}

private enum Localization {
    static let updateAvailableTitle = NSLocalizedString(
        "Update available",
        comment: "String shown to indicate the latest version of a plugin when an " +
        "update is available and highlighted to the user")
    static let upToDateTitle = NSLocalizedString(
        "Up to date",
        comment: "String shown to indicate the latest version of a plugin when an " +
        "update is available and highlighted to the user")
}


struct PluginDetailsRowView_Previews: PreviewProvider {
    private static func viewModel(
        version: String,
        versionLatest: String) -> PluginDetailsViewModel {
            let viewModel = PluginDetailsViewModel(
                siteID: 0,
                pluginName: "WooCommerce")
            viewModel.plugin = SystemPlugin(siteID: 0,
                                            plugin: "",
                                            name: "",
                                            version: version,
                                            versionLatest: versionLatest,
                                            url: "",
                                            authorName: "",
                                            authorUrl: "",
                                            networkActivated: false,
                                            active: true)
            viewModel.updateURL = URL(string: "https://woo.com")!
            return viewModel
    }

    static var previews: some View {
        Group {
            PluginDetailsRowView(viewModel: viewModel(version: "6.8.0", versionLatest: "6.11.0"))
                .previewLayout(.fixed(width: 375, height: 100))
            PluginDetailsRowView(viewModel: viewModel(version: "6.11.0", versionLatest: "6.11.0"))
                .previewLayout(.fixed(width: 375, height: 100))
        }
    }
}
