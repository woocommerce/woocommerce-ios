import Foundation
import Combine
import NetworkingWatchOS
import WooFoundationWatchOS

/// View Model for the MyStoreView
///
final class MyStoreViewModel: ObservableObject {

    /// Enum that tracks the state of the view.
    ///
    enum ViewState: Equatable {
        case idle
        case loading
        case error
        case loaded(revenue: String, totalOrders: String, totalVisitors: String, conversion: String, time: String)
    }

    private let dependencies: WatchDependencies

    /// Combine subs store.
    ///
    private var subscriptions: Set<AnyCancellable> = []

    @Published private(set) var viewState: ViewState = .idle

    init(dependencies: WatchDependencies) {
        self.dependencies = dependencies
    }

    /// Perform the initial fetch and binds the refresh trigger for further refreshes.
    ///
    @MainActor
    func fetchAndBindRefreshTrigger(trigger: AnyPublisher<Void, Never>) async {
        trigger
            .sink { [weak self] _ in
                // Do not refresh data if we are already loading it.
                guard let self, self.viewState != .loading else { return }

                Task {
                    await self.fetchStats()
                }
            }
            .store(in: &subscriptions)

        await fetchStats()
    }

    /// Fetch stats and update the view state based on the result.
    ///
    @MainActor
    private func fetchStats() async {

        if Self.shouldTransitionToLoading(state: viewState) {
            self.viewState = .loading
        }

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

    /// Determines when we should transition to a loading state.
    ///
    static private func shouldTransitionToLoading(state: ViewState) -> Bool {
        switch state {
        case .idle, .error:
            return true
        case .loading, .loaded: // If we have already loaded the data don't transition to a loading state.
            return false
        }
    }
}
