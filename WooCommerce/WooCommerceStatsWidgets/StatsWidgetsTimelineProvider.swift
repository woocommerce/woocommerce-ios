
import WidgetKit
import Foundation


/// Determines when and with what content the stats home screen widget is updated
final class StatsWidgetsTimelineProvider: TimelineProvider {
    // refresh interval of the widget, in minutes
    private let refreshInterval = 60
    // Data to be shown on placeholder widget, shown e.g when the iOS previews the widget
    private let placeholderData: StatsWidgetData
    // Earliest stats date to be fetched
    private let earliestStatsDateToFetch: Date
    // Network service to fetch the data
    private var statsWidgetsService: StatsWidgetsService?

    init(placeholderData: StatsWidgetData, earliestStatsDateToFetch: Date) {
        self.placeholderData = placeholderData
        self.earliestStatsDateToFetch = earliestStatsDateToFetch
    }

    func placeholder(in context: Context) -> StatsWidgetEntry {
        StatsWidgetEntry.storeSelected(storeName: Localization.placeholderSiteName, data: placeholderData)
    }

    func getSnapshot(in context: Context, completion: @escaping (StatsWidgetEntry) -> ()) {
        completion(placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<StatsWidgetEntry>) -> ()) {
        guard let sharedData = try? StatsWidgetsSharedDataManager.retrieveSharedData() else {
            return completion(timeline(from: .noStoreSelected))
        }

        let service = StatsWidgetsService(authToken: sharedData.authToken)
        statsWidgetsService = service

        Task {
            do {
                let statsWidgetData = try await service.fetchStatsWidgetData(for: sharedData.storeID, earliestDateToInclude: earliestStatsDateToFetch)

                completion(timeline(from: .storeSelected(storeName: sharedData.siteName, data: statsWidgetData)))
            } catch {
                completion(timeline(from: .error))
            }
        }
    }

    private func timeline(from timelineEntry: StatsWidgetEntry) -> Timeline<StatsWidgetEntry> {
        let date = Date()
        let nextRefreshDate = Calendar.current.date(byAdding: .minute, value: refreshInterval, to: date) ?? date

         return Timeline(entries: [timelineEntry], policy: .after(nextRefreshDate))
    }
}

private extension StatsWidgetsTimelineProvider {
    enum Localization {
        static let placeholderSiteName = NSLocalizedString("Your WooCommerce Store", comment: "Site name shown in the homescreen widget preview placeholder.")
    }
}
