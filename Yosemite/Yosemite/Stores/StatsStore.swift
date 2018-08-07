import Foundation
import Networking

// MARK: - StatsStore
//
public class StatsStore: Store {

    /// Registers for supported Actions.
    ///
    override public func registerSupportedActions(in dispatcher: Dispatcher) {
        dispatcher.register(processor: self, for: StatsAction.self)
    }

    /// Receives and executes Actions.
    ///
    override public func onAction(_ action: Action) {
        guard let action = action as? StatsAction else {
            assertionFailure("OrderStatsStore received an unsupported action")
            return
        }

        switch action {
        case .retrieveOrderStats(let siteID, let granularity, let latestDateToInclude, let quantity, let onCompletion):
            retrieveOrderStats(siteID: siteID, granularity: granularity, latestDateToInclude: latestDateToInclude,  quantity: quantity, onCompletion: onCompletion)
        case .retrieveSiteVisitStats(let siteID, let granularity, let latestDateToInclude, let quantity, let onCompletion):
            retrieveSiteVisitStats(siteID: siteID, granularity: granularity, latestDateToInclude: latestDateToInclude,  quantity: quantity, onCompletion: onCompletion)
        }
    }
}


// MARK: - Services!
//
private extension StatsStore  {

    /// Retrieves the order stats associated with the provided Site ID (if any!).
    ///
    func retrieveOrderStats(siteID: Int, granularity: StatGranularity, latestDateToInclude: Date, quantity: Int, onCompletion: @escaping (OrderStats?, Error?) -> Void) {

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

    /// Retrieves the site visit stats associated with the provided Site ID (if any!).
    ///
    func retrieveSiteVisitStats(siteID: Int, granularity: StatGranularity, latestDateToInclude: Date, quantity: Int, onCompletion: @escaping (SiteVisitStats?, Error?) -> Void) {

        let remote = SiteVisitStatsRemote(network: network)

        remote.loadSiteVisitorStats(for: siteID, unit: granularity, latestDateToInclude: latestDateToInclude, quantity: quantity) { (siteVisitStats, error) in
            guard let siteVisitStats = siteVisitStats else {
                onCompletion(nil, error)
                return
            }

            onCompletion(siteVisitStats, nil)
        }
    }

    /// Converts a Date into the appropriatly formatted string based on the `OrderStatGranularity`
    ///
    func buildDateString(from date: Date, with granularity: StatGranularity) -> String {
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
