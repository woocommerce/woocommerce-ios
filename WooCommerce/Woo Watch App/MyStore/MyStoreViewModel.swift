import Foundation
import NetworkingWatchOS
import WooFoundationWatchOS

/// View Model for the MyStoreView
///
final class MyStoreViewModel: ObservableObject {

    /// Enum that tracks the state of the view.
    ///
    enum ViewState {
        case idle
        case loading
        case error
        case loaded(revenue: String, totalOrders: String, totalVisitors: String, conversion: String, time: String)
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

            let visitors: String = {
                if let visitors = stats.totalVisitors {
                    return "\(visitors)"
                }
                return StoreInfoFormatter.Constants.valuePlaceholderText
            }()

            let conversion: String = {
                if let conversion = stats.conversion {
                    return StoreInfoFormatter.formattedConversionString(for: conversion)
                }
                return StoreInfoFormatter.Constants.valuePlaceholderText
            }()

            self.viewState = .loaded(revenue: StoreInfoFormatter.formattedAmountString(for: stats.revenue, with: dependencies.currencySettings),
                                     totalOrders: "\(stats.totalOrders)",
                                     totalVisitors: visitors,
                                     conversion: conversion,
                                     time: StoreInfoFormatter.currentFormattedTime())
        } catch {
            DDLogError("⛔️ Error fetching watch today stats: \(error)")
            self.viewState = .error
        }
    }
}
