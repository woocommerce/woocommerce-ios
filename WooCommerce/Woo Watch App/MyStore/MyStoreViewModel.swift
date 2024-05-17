import Foundation
import NetworkingWatchOS

/// View Model for the MyStoreView
///
final class MyStoreViewModel: ObservableObject {

    static let valuePlaceholderText = "-"

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
                return Self.valuePlaceholderText
            }()

            let conversion: String = {
                if let conversion = stats.conversion {
                    return Self.formattedConversionString(for: conversion)
                }
                return Self.valuePlaceholderText
            }()

            self.viewState = .loaded(revenue: Self.formattedAmountString(for: stats.revenue),
                                     totalOrders: "\(stats.totalOrders)",
                                     totalVisitors: visitors,
                                     conversion: conversion,
                                     time: Self.currentFormattedTime())
        } catch {
            DDLogError("⛔️ Error fetching watch today stats: \(error)")
            self.viewState = .error
        }
    }
}

/// Copied from `StoreInfoProvider`. Should be moved into a single file for easier maintainability.
///
private extension MyStoreViewModel {
    static func formattedAmountString(for amountValue: Decimal) -> String {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .currency
        numberFormatter.minimumFractionDigits = 2
        numberFormatter.currencyDecimalSeparator = "."
        numberFormatter.currencyGroupingSeparator = ","
        return numberFormatter.string(from: amountValue as NSNumber) ?? valuePlaceholderText
    }

    static func formattedConversionString(for conversionRate: Double) -> String {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .percent
        numberFormatter.minimumFractionDigits = 1

        // do not add 0 fraction digit if the percentage is round
        let minimumFractionDigits = floor(conversionRate * 100.0) == conversionRate * 100.0 ? 0 : 1
        numberFormatter.minimumFractionDigits = minimumFractionDigits
        return numberFormatter.string(from: conversionRate as NSNumber) ?? valuePlaceholderText
    }

    /// Returns the current time formatted as `10:24 PM` or `22:24` depending on the device settings.
    ///
    static func currentFormattedTime() -> String {
        let timeFormatter = DateFormatter()
        timeFormatter.timeStyle = .short
        timeFormatter.dateStyle = .none
        return timeFormatter.string(from: Date.now)
    }
}
