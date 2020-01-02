import Networking

/// MARK: AvailabilityStore
///
final public class AvailabilityStore: Store {
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
        let date = String(describing: Date().timeIntervalSinceReferenceDate)
        let remote = OrderStatsRemoteV4(network: network)
        remote.loadOrderStats(for: siteID,
                              unit: .yearly,
                              earliestDateToInclude: date,
                              latestDateToInclude: date,
                              quantity: 1) { (_, error) in
                                if let error = error as? DotcomError, error == .noRestRoute {
                                    onCompletion(false)
                                } else {
                                    onCompletion(true)
                                }
        }
    }
}
