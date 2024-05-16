import Foundation
import Yosemite
import protocol WooFoundation.Analytics

/// View model for `MostActiveCouponsCard`.
///
final class MostActiveCouponsCardViewModel: ObservableObject {
    // Set externally to trigger callback upon hiding the Coupons card.
    var onDismiss: (() -> Void)?

    @Published private(set) var timeRange = StatsTimeRangeV4.today
    @Published private(set) var syncingData = false
    @Published private(set) var syncingError: Error?
    @Published private(set) var coupons: [Coupon] = []
    @Published private(set) var timeRangeText = ""

    let siteID: Int64
    let siteTimezone: TimeZone
    private let stores: StoresManager
    private let analytics: Analytics

    init(siteID: Int64,
         siteTimezone: TimeZone = .siteTimezone,
         stores: StoresManager = ServiceLocator.stores,
         analytics: Analytics = ServiceLocator.analytics) {
        self.siteID = siteID
        self.siteTimezone = siteTimezone
        self.stores = stores
        self.analytics = analytics

        $timeRange
            .removeDuplicates()
            .map({ timeRange in
                guard let timeRangeViewModel = StatsTimeRangeBarViewModel(timeRange: timeRange, timezone: siteTimezone) else {
                    return ""
                }
                return timeRangeViewModel.timeRangeText
            })
            .assign(to: &$timeRangeText)

        Task { @MainActor in
            self.timeRange = await loadLastTimeRange() ?? .today
            await reloadData()
        }
    }

    func dismiss() {
        analytics.track(event: .DynamicDashboard.hideCardTapped(type: .coupons))
        onDismiss?()
    }

    func didSelectTimeRange(_ newTimeRange: StatsTimeRangeV4) {
        timeRange = newTimeRange
        saveLastTimeRange(timeRange)

        Task { [weak self] in
            await self?.reloadData()
        }
    }

    @MainActor
    func reloadData() async {
        syncingData = true
        syncingError = nil
        do {
            let activeCouponReports = try await mostActiveCoupons()
            coupons = try await loadCouponDetails(for: activeCouponReports)
        } catch {
            syncingError = error
            DDLogError("⛔️ Dashboard (Most active coupons) — Error loading most active coupons: \(error)")
        }
        syncingData = false
    }
}

// MARK: - Data for `MostActiveCouponsCardViewModel`
//
extension MostActiveCouponsCardViewModel {
    var startDateForCustomRange: Date {
        if case let .custom(startDate, _) = timeRange {
            return startDate
        }
        return Date(timeInterval: -Constants.thirtyDaysInSeconds, since: endDateForCustomRange) // 30 days before end date
    }

    var endDateForCustomRange: Date {
        if case let .custom(_, endDate) = timeRange {
            return endDate
        }
        return Date()
    }

    var buttonTitleForCustomRange: String? {
        if case .custom = timeRange {
            return nil
        }
        return Localization.addCustomRange
    }
}

private extension MostActiveCouponsCardViewModel {
    @MainActor
    func loadLastTimeRange() async -> StatsTimeRangeV4? {
        await withCheckedContinuation { continuation in
            let action = AppSettingsAction.loadLastSelectedMostActiveCouponsTimeRange(siteID: siteID) { timeRange in
                continuation.resume(returning: timeRange)
            }
            stores.dispatch(action)
        }
    }

    func saveLastTimeRange(_ timeRange: StatsTimeRangeV4) {
        let action = AppSettingsAction.setLastSelectedMostActiveCouponsTimeRange(siteID: siteID, timeRange: timeRange)
        stores.dispatch(action)
    }

    @MainActor
    func loadCouponDetails(for reports: [CouponReport]) async throws -> [Coupon] {
        guard reports.isNotEmpty else {
            return []
        }
        let couponIDs = reports.map({ $0.couponID })
        return try await withCheckedThrowingContinuation { continuation in
            stores.dispatch(CouponAction.loadCoupons(siteID: siteID,
                                                     couponIDs: couponIDs) { result in
                continuation.resume(with: result)
            })
        }
    }

    @MainActor
    func mostActiveCoupons() async throws -> [CouponReport] {
        try await withCheckedThrowingContinuation { continuation in
            stores.dispatch(CouponAction.loadMostActiveCoupons(siteID: siteID, timeRange: timeRange, siteTimezone: siteTimezone) { result in
                continuation.resume(with: result)
            })
        }
    }
}

// MARK: Constants
//
private extension MostActiveCouponsCardViewModel {
    enum Constants {
        static let thirtyDaysInSeconds: TimeInterval = 86400*30
    }
    enum Localization {
        static let addCustomRange = NSLocalizedString(
            "mostActiveCouponsCardViewModel.addCustomRange",
            value: "Add",
            comment: "Button in date range picker to add a Custom Range tab"
        )
    }
}
