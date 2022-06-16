
import WidgetKit
import SwiftUI
import Yosemite
import Networking
import WooFoundation

enum StatsProviderError: Error {
    case attemptToRequestWithoutNetworkSet
}

final class StatsProvider: TimelineProvider {
    // refresh interval of the widget, in minutes
    let refreshInterval = 60

    private let placeholderData: StatsWidgetData
    private let earliestDateToInclude: Date
    private var sharedData: SharedData?
    private var statsWidgetsService: StatsWidgetsService?

    private var orderStatsRemoteV4: OrderStatsRemoteV4?
    private var siteVisitStatsRemote: SiteVisitStatsRemote?
    private var network: AlamofireNetwork?

    init(placeholderData: StatsWidgetData, earliestDateToInclude: Date) {
        self.placeholderData = placeholderData
        self.earliestDateToInclude = earliestDateToInclude
        self.sharedData = try? SharedDataManager.retrieveSharedData()

        if let authToken = sharedData?.authToken {
            statsWidgetsService = StatsWidgetsService(authToken: authToken)
        }
    }

    func placeholder(in context: Context) -> StatsWidgetEntry {
        StatsWidgetEntry.siteSelected(siteName: "Your WooCommerce Store", data: placeholderData)
    }

    func getSnapshot(in context: Context, completion: @escaping (StatsWidgetEntry) -> ()) {
        completion(placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<StatsWidgetEntry>) -> ()) {
        let date = Date()
        let nextRefreshDate = Calendar.current.date(byAdding: .minute, value: refreshInterval, to: date) ?? date
        let privateCompletion = { (timelineEntry: StatsWidgetEntry) in
            let timeline = Timeline(entries: [timelineEntry], policy: .after(nextRefreshDate))
                    completion(timeline)
        }

        guard let sharedData = sharedData,
              let service = statsWidgetsService else {
            return privateCompletion(.noSite)
        }

        Task {
            do {
                let statsWidgetData = try await service.fetchStatsWidgetData(for: sharedData.storeID, earliestDateToInclude: earliestDateToInclude)

                privateCompletion(StatsWidgetEntry.siteSelected(siteName: sharedData.siteName, data: statsWidgetData))
            } catch {
                privateCompletion(.error)
            }
        }
    }
}
