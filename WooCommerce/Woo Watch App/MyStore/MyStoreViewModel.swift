import Foundation
import NetworkingWatchOS

/// View Model for the MyStoreView
///
final class MyStoreViewModel: ObservableObject {

    /// Enum that tracks the state of the view.
    ///
    enum ViewState {
        case idle
        case loading
        case error
        case loaded(revenue: String, totalOrders: String, totalVisitors: String, conversion: String)

        /// Temporary description.
        ///
        var description: String {
            switch self {
            case .idle:
                return ""
            case .loading:
                return "Loading"
            case .error:
                return "Error"
            case let .loaded(revenue, totalOrders, totalVisitors, conversion):
                return "Revenue: \(revenue)\nOrders: \(totalOrders)\nVisitors: \(totalVisitors)\nConversion: \(conversion)\n"
            }
        }
    }

    private let dependencies: WatchDependencies

    @Published private(set) var viewState: ViewState = .idle

    init(dependencies: WatchDependencies) {
        self.dependencies = dependencies
    }

    /// Fetch stats and update the view state based on the result.
    ///
    @MainActor
    func fetchStats() async {
        self.viewState = .loading
        let service = StoreInfoDataService(credentials: dependencies.credentials)
        do {
            let stats = try await service.fetchTodayStats(for: dependencies.storeID)
            self.viewState = .loaded(revenue: "\(stats.revenue)",
                                     totalOrders: "\(stats.totalOrders)",
                                     totalVisitors: "\(stats.totalVisitors ?? 0)",
                                     conversion: "\(stats.conversion ?? 0.0)")
        } catch {
            DDLogError("⛔️ Error fetching watch today stats: \(error)")
            self.viewState = .error
        }
    }
}
