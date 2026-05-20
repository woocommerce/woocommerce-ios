import Yosemite

/// Helper that defines which `status` a new order should initially have.
///
struct NewOrderInitialStatusResolver {
    /// Current site ID
    ///
    private let siteID: Int64

    /// Plugins service.
    ///
    private let pluginsService: PluginsServiceProtocol

    /// Defines the WC version where `auto-draft` should be available.
    ///
    private let draftMinSupportedVersion = "6.3.0"

    init(siteID: Int64, pluginsService: PluginsServiceProtocol = PluginsService(storageManager: ServiceLocator.storageManager)) {
        self.siteID = siteID
        self.pluginsService = pluginsService
    }

    /// Decides the initial `status` for a new order based on the current store version.
    ///
    @MainActor
    func resolve(onCompletion: @escaping (OrderStatusEnum) -> ()) {
        guard let wooPlugin = pluginsService.loadPluginInStorage(siteID: siteID, plugin: .wooCommerce, isActive: true) else {
            onCompletion(.pending)
            return
        }

        // auto-draft should exists in versions greater than `6.3.0`
        switch draftMinSupportedVersion.compare(wooPlugin.version, options: .numeric) {
        case .orderedAscending, .orderedSame:
            onCompletion(.autoDraft)
        case .orderedDescending:
            onCompletion(.pending)
        }
    }
}
