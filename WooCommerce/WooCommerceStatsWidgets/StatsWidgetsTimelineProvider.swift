
import WidgetKit
import SwiftUI
import Yosemite
import Networking
import WooFoundation

final class StatsWidgetsTimelineProvider: TimelineProvider {
    // refresh interval of the widget, in minutes
    let refreshInterval = 60

    private let placeholderData: StatsWidgetData
    private let earliestDateToInclude: Date
    private var statsWidgetsService: StatsWidgetsService?

    init(placeholderData: StatsWidgetData, earliestDateToInclude: Date) {
        self.placeholderData = placeholderData
        self.earliestDateToInclude = earliestDateToInclude
    }

    func placeholder(in context: Context) -> StatsWidgetEntry {
        StatsWidgetEntry.siteSelected(siteName: Localization.placeholderSiteName, data: placeholderData)
    }

    func getSnapshot(in context: Context, completion: @escaping (StatsWidgetEntry) -> ()) {
        completion(placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<StatsWidgetEntry>) -> ()) {
        guard let sharedData = try? StatsWidgetsSharedDataManager.retrieveSharedData() else {
            return completion(timeline(from: .noSite))
        }

        let service = StatsWidgetsService(authToken: sharedData.authToken)
        statsWidgetsService = service

        Task {
            do {
                let statsWidgetData = try await service.fetchStatsWidgetData(for: sharedData.storeID, earliestDateToInclude: earliestDateToInclude)

                completion(timeline(from: .siteSelected(siteName: sharedData.siteName, data: statsWidgetData)))
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
