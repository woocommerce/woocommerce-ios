import Foundation
import Yosemite
import protocol Storage.StorageManagerType

protocol PluginDetailsViewModel {
    var version: String { get }
    var versionLatest: String? { get }
    var title: String { get }
    var updateURL: URL? { get }
}

final class WooCommercePluginViewModel: PluginDetailsViewModel {
    var updateURL: URL? {
        guard let url = storesManager.sessionManager.defaultSite?.pluginsURL,
              updateAvailable
        else {
            return nil
        }

        return URL(string: url)
    }

    var updateAvailable: Bool {
        guard let plugin = plugin else {
            return false
        }
        return !VersionHelpers.isVersionSupported(version: plugin.version, minimumRequired: plugin.versionLatest)
    }

    var version: String {
        plugin?.version ?? Localization.unknownVersionValue
    }

    var versionLatest: String? {
        plugin?.versionLatest
    }

    private var plugin: SystemPlugin?

    let title: String

    /// ID of the site to load plugins for
    ///
    private let siteID: Int64

    /// Reference to the StoresManager to dispatch Yosemite Actions.
    ///
    private let storesManager: StoresManager

    /// StorageManager to load plugins from storage
    ///
    private let storageManager: StorageManagerType

    /// Results controller for the plugin list
    ///
    private lazy var resultsController: ResultsController<StorageSystemPlugin> = {
        let predicate = NSPredicate(format: "siteID = %ld AND name = %@", self.siteID, "WooCommerce")
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

    init(siteID: Int64,
         storesManager: StoresManager = ServiceLocator.stores,
         storageManager: StorageManagerType = ServiceLocator.storageManager,
         title: String = Localization.pluginDetailTitle) {
        self.siteID = siteID
        self.storesManager = storesManager
        self.storageManager = storageManager
        self.title = title
        observeWooCommercePlugin { self.plugin = self.resultsController.fetchedObjects.first }
    }

    /// Start fetching and observing plugin data from local storage.
    ///
    func observeWooCommercePlugin(onDataChanged: @escaping () -> Void) {
        resultsController.onDidChangeContent = onDataChanged
    }
}

private enum Localization {
    static let pluginDetailTitle = NSLocalizedString(
        "WooCommerce Version",
        comment: "Title for the WooCommerce plugin version detail row in settings. This is displayed with the " +
        "current version number, and whether an update is available.")

    static let unknownVersionValue = NSLocalizedString(
        "unknown",
        comment: "Value for the WooCommerce plugin version detail row in settings, when the version is unknown. " +
        "This is in place of the current version number.")
}
