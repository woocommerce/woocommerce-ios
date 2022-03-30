import Yosemite

/// Helper that defines which `status` a new order should initially have.
///
struct NewOrderInitialStatusResolver {
    /// Current site ID
    ///
    private let siteID: Int64

    /// Stores.
    ///
    private let stores: StoresManager

    /// Defines the WC version where `auto-draft` should be available.
    ///
    private let draftMinSupportedVersion = "6.3.0"

    /// WooCommerce plugin name.
    ///
    private let wcPluginName = "WooCommerce"

    init(siteID: Int64, stores: StoresManager = ServiceLocator.stores) {
        self.siteID = siteID
        self.stores = stores
    }

    /// Decides the initial `status` for a new order based on the current store version.
    ///
    func resolve(onCompletion: @escaping (OrderStatusEnum) -> ()) {
        let action = SystemStatusAction.fetchSystemPlugin(siteID: siteID, systemPluginName: wcPluginName) { wooPlugin in
            guard let wooPlugin = wooPlugin else {
                return onCompletion(.pending)
            }

            // auto-draft should exists in versions greater than `6.3.0`
            switch draftMinSupportedVersion.compare(wooPlugin.version, options: .numeric) {
            case .orderedAscending, .orderedSame:
                onCompletion(.autoDraft)
            case .orderedDescending:
                onCompletion(.pending)
            }
        }
        stores.dispatch(action)
    }
}
