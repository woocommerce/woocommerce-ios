import Networking
import Storage

// MARK: AvailabilityStore
//
final public class AvailabilityStore: Store {
    private let orderStatsRemote: OrderStatsRemoteV4

    public override init(dispatcher: Dispatcher, storageManager: StorageManagerType, network: Network) {
        self.orderStatsRemote = OrderStatsRemoteV4(network: network)
        super.init(dispatcher: dispatcher, storageManager: storageManager, network: network)
    }

    /// Registers for supported Actions.
    ///
    override public func registerSupportedActions(in dispatcher: Dispatcher) {
        dispatcher.register(processor: self, for: AvailabilityAction.self)
    }

    /// Receives and executes Actions.
    ///
    override public func onAction(_ action: Action) {
        guard let action = action as? AvailabilityAction else {
            assertionFailure("\(String(describing: self)) received an unsupported action")
            return
        }

        switch action {
        case .checkStatsV4Availability(let siteID, let onCompletion):
            checkStatsV4Availability(siteID: siteID, onCompletion: onCompletion)
        }
    }
}

// MARK: - Services!
//
private extension AvailabilityStore {
    /// Checks if Stats v4 is available for the site.
    ///
    func checkStatsV4Availability(siteID: Int64,
                                  onCompletion: @escaping (_ isStatsV4Available: Bool) -> Void) {
        orderStatsRemote.loadOrderStats(for: siteID,
                              unit: .yearly,
                              earliestDateToInclude: Date(),
                              latestDateToInclude: Date(),
                              quantity: 1) { result in
            switch result {
            case .failure(let error) where error as? DotcomError == .noRestRoute:
                onCompletion(false)
            default:
                onCompletion(true)
            }
        }
    }
}
