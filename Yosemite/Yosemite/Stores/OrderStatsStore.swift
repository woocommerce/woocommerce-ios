import Foundation
import Networking

// MARK: - OrderStatsStore
//
public class OrderStatsStore: Store {

    /// Registers for supported Actions.
    ///
    override public func registerSupportedActions(in dispatcher: Dispatcher) {
        dispatcher.register(processor: self, for: OrderStatsAction.self)
    }

    /// Receives and executes Actions.
    ///
    override public func onAction(_ action: Action) {
        guard let action = action as? OrderStatsAction else {
            assertionFailure("OrderStatsStore received an unsupported action")
            return
        }

        switch action {
        case .retrieveOrderStats(let siteID, let granularity, let latestDateToInclude, let quantity, let onCompletion):
            retrieveOrderStats(siteID: siteID, granularity: granularity, latestDateToInclude: latestDateToInclude,  quantity: quantity, onCompletion: onCompletion)
        }
    }
}


// MARK: - Services!
//
private extension OrderStatsStore  {

    /// Retrieves the order stats associated with the provided Site ID (if any!).
    ///
    func retrieveOrderStats(siteID: Int, granularity: OrderStatGranularity, latestDateToInclude: Date, quantity: Int, onCompletion: @escaping (OrderStats?, Error?) -> Void) {

        let remote = OrderStatsRemote(network: network)
        let formattedDateString = buildDateString(from: latestDateToInclude, with: granularity)

        remote.loadOrderStats(for: siteID, unit: granularity, latestDateToInclude: formattedDateString, quantity: quantity) { (orderStats, error) in
            guard let orderStats = orderStats else {
                onCompletion(nil, error)
                return
            }

            onCompletion(orderStats, nil)
        }
    }

    /// Converts a Date into the appropriatly formatted string based on the `OrderStatGranularity`
    ///
    func buildDateString(from date: Date, with granularity: OrderStatGranularity) -> String {
        switch granularity {
        case .day:
            return DateFormatter.Stats.statsDayFormatter.string(from: date)
        case .week:
            return DateFormatter.Stats.statsWeekFormatter.string(from: date)
        case .month:
            return DateFormatter.Stats.statsMonthFormatter.string(from: date)
        case .year:
            return DateFormatter.Stats.statsYearFormatter.string(from: date)
        }
    }
}
