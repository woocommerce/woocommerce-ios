import Foundation
import Yosemite
import protocol Storage.StorageManagerType

final class PluginDetailsViewModel: ObservableObject {
    /// ID of the site to load plugins for
    ///
    private let siteID: Int64

    /// Name of the plugin to show details for
    ///
    private let pluginName: String

    /// Reference to the StoresManager to dispatch Yosemite Actions.
    ///
    private let storesManager: StoresManager

    /// StorageManager to load plugins from storage
    ///
    private let storageManager: StorageManagerType

    /// Results controller for the plugin list
    ///
    private lazy var resultsController: ResultsController<StorageSystemPlugin> = {
        let predicate = NSPredicate(format: "siteID = %ld AND name = %@", self.siteID, pluginName)
        let resultsController = ResultsController<StorageSystemPlugin>(
            storageManager: storageManager,
            matching: predicate,
            sortedBy: []
        )

        do {
            try resultsController.performFetch()
            plugin = resultsController.fetchedObjects.first
        } catch {
            DDLogError("⛔️ Error fetching WooCommerce plugin details!")
        }
        return resultsController
    }()

    /// Title for the plugin details row
    ///
    let title: String

    var updateAvailable: Bool {
        guard let plugin = plugin else {
            return false
        }
        return !VersionHelpers.isVersionSupported(version: plugin.version, minimumRequired: plugin.versionLatest)
    }

    /// URL for the plugins page in WP-admin, used for the update webview when an update is available
    ///
    @Published var updateURL: URL?

    /// Version of the plugin installed on the current site
    ///
    @Published var version: String

    /// Latest version of the plugin installed on the current site
    ///
    @Published var versionLatest: String?

    var plugin: SystemPlugin? {
        didSet {
            version = plugin?.version ?? Localization.unknownVersionValue
            versionLatest = plugin?.versionLatest
            updateURL = updateURL(for: plugin)
        }
    }

    init(siteID: Int64,
         pluginName: String,
         storesManager: StoresManager = ServiceLocator.stores,
         storageManager: StorageManagerType = ServiceLocator.storageManager) {
        self.siteID = siteID
        self.pluginName = pluginName
        self.storesManager = storesManager
        self.storageManager = storageManager
        self.title = String(format: Localization.pluginDetailTitle, pluginName)
        self.plugin = nil
        self.updateURL = nil
        self.version = ""
        self.versionLatest = nil
        observePlugin { self.plugin = self.resultsController.fetchedObjects.first }
    }

    /// Start fetching and observing plugin data from local storage.
    ///
    private func observePlugin(onDataChanged: @escaping () -> Void) {
        resultsController.onDidChangeContent = onDataChanged
    }

    /// Used to refresh the store after the webview is used to perform an update
    ///
    func refreshPlugin() {
        let action = SystemStatusAction.synchronizeSystemPlugins(siteID: siteID) { _ in }
        storesManager.dispatch(action)
    }
}

private extension PluginDetailsViewModel {
    private func updateURL(for plugin: SystemPlugin?) -> URL? {
        guard let url = storesManager.sessionManager.defaultSite?.pluginsURL,
              updateAvailable(for: plugin)
        else {
            return nil
        }

        return URL(string: url)
    }

    private func updateAvailable(for plugin: SystemPlugin?) -> Bool {
        guard let plugin = plugin else {
            return false
        }
        return !VersionHelpers.isVersionSupported(version: plugin.version, minimumRequired: plugin.versionLatest)
    }

}

private enum Localization {
    static let pluginDetailTitle = NSLocalizedString(
        "%1$@ Version",
        comment: "Title for the plugin version detail row in settings. %1$@ is a placeholder for the plugin name. " +
        "This is displayed with the current version number, and whether an update is available.")

    static let unknownVersionValue = NSLocalizedString(
        "unknown",
        comment: "Value for the WooCommerce plugin version detail row in settings, when the version is unknown. " +
        "This is in place of the current version number.")
}
