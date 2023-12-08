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

// Temporary service for testing plugin management via webview or api calls:
final class PluginManagementService {
    enum ManageVia {
        case webView
        case apiCall
    }

    let managePluginVia: ManageVia

    var siteID: Int64 {
        ServiceLocator.stores.sessionManager.defaultSite?.siteID ?? 0
    }

    init(managePluginVia: ManageVia) {
        self.managePluginVia = managePluginVia
    }

    func updatePlugin(_ pluginName: String, onCompletion: @escaping (Result<Void, Error>) -> Void) {
        /* TODO:
         - Indeally a new action for updating, since only install is not enough (need uninstall first) or we'll get a [folder_exists] error
         - Plugin name cannot be used here, we need the slug
         */
        if managePluginVia == .apiCall {
            let action = SitePluginAction.installSitePlugin(siteID: siteID,
                                                            slug: pluginName,
                                                            onCompletion: { result in
                switch result {
                case .success:
                    onCompletion(.success(()))
                case .failure(let error):
                    DDLogError("Failed to install/update '\(pluginName)'. Error: \(error)")
                    onCompletion(.failure(error))
                }
            })
            ServiceLocator.stores.dispatch(action)
        } else if managePluginVia == .webView {
            onCompletion(.success(()))
        }
    }
}

struct PluginListDetailView: View {

    @ObservedObject private var viewModel: PluginListViewModel
    private let service: PluginManagementService = PluginManagementService(managePluginVia: .apiCall)

    init(viewModel: PluginListViewModel) {
        self.viewModel = viewModel
    }

    @State private var showWebView = false
    @State private var isLoading = false
    @State var webViewPresented = false

    var updateUrl: URL? {
        let pluginsURL = ServiceLocator.stores.sessionManager.defaultSite?.pluginsURL
        return URL(string: pluginsURL ?? "https://woo.com")!
    }

    var siteID: Int64 {
        ServiceLocator.stores.sessionManager.defaultSite?.siteID ?? 0
    }

    var body: some View {
        ScrollView {
            ForEach(viewModel.pluginList(), id: \.self) { plugin in
                let pluginDetailsViewModel = PluginDetailsViewModel(siteID: siteID,
                                                                    pluginName: plugin.name)
                NavigationRow(content: {
                    PluginDetailsRowContent(viewModel: pluginDetailsViewModel)
                        .redacted(reason: isLoading ? .placeholder : [])
                }, action: {
                    service.updatePlugin(plugin.name) { result in
                        switch result {
                        default:
                            print("\(plugin.name) tapped")
                            isLoading = false
                            if service.managePluginVia == .webView {
                                webViewPresented = true
                            }
                        }
                    }
                    isLoading = true
                })
                Divider()
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
