import Foundation
import Yosemite
import protocol WooFoundation.Analytics
import protocol Storage.StorageManagerType
import enum Networking.DotcomError
import enum Networking.NetworkError

/// View model for `MostActiveCouponsCard`.
///
@MainActor
final class MostActiveCouponsCardViewModel: ObservableObject {
    // Set externally to trigger callback upon hiding the Coupons card.
    var onDismiss: (() -> Void)?

    @Published private(set) var timeRange = StatsTimeRangeV4.today
    @Published private(set) var syncingData = false
    @Published private(set) var syncingError: Error?
    @Published private(set) var rows: [MostActiveCouponRowViewModel] = []
    @Published private(set) var timeRangeText = ""
    @Published private(set) var analyticsEnabled = true

    let siteID: Int64
    let siteTimezone: TimeZone
    private let stores: StoresManager
    private let storageManager: StorageManagerType
    private let analytics: Analytics
    private var resultsController: ResultsController<StorageCoupon>?

    init(siteID: Int64,
         siteTimezone: TimeZone = .siteTimezone,
         stores: StoresManager = ServiceLocator.stores,
         storageManager: StorageManagerType = ServiceLocator.storageManager,
         analytics: Analytics = ServiceLocator.analytics) {
        self.siteID = siteID
        self.siteTimezone = siteTimezone
        self.stores = stores
        self.storageManager = storageManager
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
        analytics.track(event: .DynamicDashboard.cardLoadingStarted(type: .coupons))
        syncingData = true
        syncingError = nil
        rows = []
        resultsController = nil

        do {
            let couponReports = try await fetchMostActiveCoupons()

            if couponReports.isNotEmpty {
                /// Load and display coupons from storage
                configureResultsController(for: couponReports)

                if rows.count < Constants.numberOfCouponsToDisplay /// Less then expected number of coupons are displayed.
                    && couponReports.count >= Constants.numberOfCouponsToDisplay { /// Coupon reports count is at or above expected count.
                    /// Fetch from remote as some coupons are not being displayed as they are not available in storage
                    try await synchronizeCoupons(for: couponReports)
                } else {
                    /// Refresh coupons in background
                    Task { @MainActor in
                        try await synchronizeCoupons(for: couponReports)
                    }
                }
            }

            analyticsEnabled = true
            analytics.track(event: .DynamicDashboard.cardLoadingCompleted(type: .coupons))
        } catch {
            switch error {
            case DotcomError.noRestRoute, NetworkError.notFound:
                analyticsEnabled = false
            default:
                analyticsEnabled = true
            }
            syncingError = error
            DDLogError("⛔️ Dashboard (Most active coupons) — Error loading most active coupons: \(error)")
            analytics.track(event: .DynamicDashboard.cardLoadingFailed(type: .coupons, error: error))
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
    func configureResultsController(for couponReports: [CouponReport]) {
        let resultsController = ResultsController<StorageCoupon>(storageManager: storageManager,
                                                                 matching: NSPredicate(format: "siteID == %lld AND couponID IN %@",
                                                                                       siteID, couponReports.map({ $0.couponID })),
                                                                 sortedBy: [])
        self.resultsController = resultsController
        resultsController.onDidChangeContent = { [weak self] in
            self?.updateResults(for: couponReports)
        }
        resultsController.onDidResetContent = { [weak self] in
            self?.updateResults(for: couponReports)
        }

        do {
            try resultsController.performFetch()
            updateResults(for: couponReports)
        } catch {
            ServiceLocator.crashLogging.logError(error)
        }
    }

    func updateResults(for couponReports: [CouponReport]) {
        guard let coupons = resultsController?.fetchedObjects else {
            return
        }

        rows = Array(couponReports
            .compactMap { report in
                guard let coupon = coupons.first(where: { $0.couponID == report.couponID }) else {
                    return nil
                }
                return MostActiveCouponRowViewModel(coupon: coupon,
                                                    report: report)
            }
            .prefix(Constants.numberOfCouponsToDisplay))
    }

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
    func synchronizeCoupons(for couponReports: [CouponReport]) async throws {
        guard couponReports.isNotEmpty else {
            return
        }
        let couponIDs = couponReports.map({ $0.couponID })
        try await withCheckedThrowingContinuation { continuation in
            stores.dispatch(CouponAction.loadCoupons(siteID: siteID,
                                                     couponIDs: couponIDs) { result in
                switch result {
                case .success:
                    continuation.resume()
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            })
        }
    }

    @MainActor
    func fetchMostActiveCoupons() async throws -> [CouponReport] {
        try await withCheckedThrowingContinuation { continuation in
            stores.dispatch(CouponAction.loadMostActiveCoupons(siteID: siteID,
                                                               numberOfCouponsToLoad: Constants.numberOfCouponsToDisplay * 2,
                                                               timeRange: timeRange,
                                                               siteTimezone: siteTimezone) { result in
                continuation.resume(with: result)
            })
        }
    }
}

// MARK: Constants
//
private extension MostActiveCouponsCardViewModel {
    enum Constants {
        static let numberOfCouponsToDisplay = 3
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
