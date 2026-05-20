import Foundation
import Observation
import Yosemite

/// View model for `PushNotificationPreferencesView` and the per-section detail
/// screens. Setters mutate `displayed`; `save()` diffs against `lastSaved` and
/// dispatches a single update.
///
@MainActor
@Observable
final class PushNotificationPreferencesViewModel {

    enum LoadState: Equatable {
        case loading
        case loaded
        case error
    }

    private(set) var loadState: LoadState = .loading

    private(set) var displayed = PushNotificationPreferences()
    private(set) var lastSaved = PushNotificationPreferences()

    var hasUnsavedChanges: Bool { displayed != lastSaved }

    var isStoreOrderEnabled: Bool { displayed.storeOrder?.enabled ?? false }
    var isStoreReviewEnabled: Bool { displayed.storeReview?.enabled ?? false }
    var isStoreStockEnabled: Bool { displayed.storeStock?.enabled ?? false }

    /// `nil` means "all orders".
    var storeOrderMinAmount: Decimal? { displayed.storeOrder?.minAmount }

    /// Last positive threshold seen, used to restore the value when the user
    /// toggles "Only high-value orders" back on after switching to "All new orders".
    private(set) var lastKnownStoreOrderMinAmount: Decimal?

    static let defaultStoreOrderMinAmount: Decimal = 100

    var errorNotice: Notice?

    private let siteID: Int64
    private let stores: StoresManager

    init(siteID: Int64, stores: StoresManager = ServiceLocator.stores) {
        self.siteID = siteID
        self.stores = stores
    }

    func load() async {
        loadState = .loading
        do {
            let preferences = try await withCheckedThrowingContinuation { continuation in
                stores.dispatch(NotificationAction.loadPushNotificationPreferences(siteID: siteID) { result in
                    continuation.resume(with: result)
                })
            }
            // Preserve in-progress edits across reloads. `lastSaved` always
            // advances so the next save still diffs against the latest server.
            if !hasUnsavedChanges {
                displayed = preferences
            }
            lastSaved = preferences
            rememberLastKnownMinAmount(from: preferences.storeOrder?.minAmount)
            loadState = .loaded
        } catch {
            DDLogError("⛔️ Error loading push notification preferences for siteID=\(siteID): \(error)")
            loadState = .error
        }
    }

    /// Persists the diff between `displayed` and `lastSaved`. Returns `true`
    /// on success; on failure publishes `errorNotice` and keeps `displayed`
    /// intact so the caller can retry.
    func save() async -> Bool {
        let pendingDiff = makeDiff(from: lastSaved, to: displayed)
        guard !pendingDiff.isEmpty else { return true }
        do {
            let server = try await withCheckedThrowingContinuation { continuation in
                stores.dispatch(NotificationAction.updatePushNotificationPreferences(siteID: siteID,
                                                                                     changes: pendingDiff) { result in
                    continuation.resume(with: result)
                })
            }
            lastSaved = server
            rememberLastKnownMinAmount(from: server.storeOrder?.minAmount)
            // Adopt the server's view so any clamped field (e.g. negative
            // threshold → nil) shows correctly without re-triggering
            // `hasUnsavedChanges`.
            displayed = server
            return true
        } catch {
            DDLogError("⛔️ Error saving push notification preferences: \(error)")
            errorNotice = Notice(title: Localization.errorNoticeTitle,
                                 message: Localization.errorNoticeMessage,
                                 feedbackType: .error)
            return false
        }
    }

    func setStoreOrderEnabled(_ newValue: Bool) {
        displayed = displayed.with(storeOrder: .init(enabled: newValue,
                                                     minAmount: displayed.storeOrder?.minAmount))
    }

    /// Reverts only the new-order section of `displayed` to `lastSaved`.
    /// Other sections are left untouched — their detail screens own their
    /// own discard paths.
    func discardStoreOrderEdits() {
        displayed = PushNotificationPreferences(storeOrder: lastSaved.storeOrder,
                                                storeReview: displayed.storeReview,
                                                storeStock: displayed.storeStock)
    }

    func setStoreOrderMinAmount(_ newValue: Decimal?) {
        let normalized: Decimal? = {
            guard let value = newValue, value > 0 else { return nil }
            return value
        }()
        rememberLastKnownMinAmount(from: normalized)
        displayed = displayed.with(storeOrder: .init(enabled: isStoreOrderEnabled,
                                                     minAmount: normalized))
    }

    func setStoreReviewEnabled(_ newValue: Bool) {
        displayed = displayed.with(storeReview: .init(enabled: newValue,
                                                      maxRating: displayed.storeReview?.maxRating))
    }

    func setStoreStockEnabled(_ newValue: Bool) {
        let existing = displayed.storeStock
        displayed = displayed.with(storeStock: .init(enabled: newValue,
                                                     lowStock: existing?.lowStock,
                                                     outOfStock: existing?.outOfStock,
                                                     onBackorder: existing?.onBackorder))
    }
}

private extension PushNotificationPreferencesViewModel {
    /// Populates only the sections that differ between `baseline` and `target`.
    /// Whole-section comparison: any change inside a section emits the section
    /// as a complete object, matching the server's section-level merge.
    func makeDiff(from baseline: PushNotificationPreferences,
                  to target: PushNotificationPreferences) -> PushNotificationPreferences {
        PushNotificationPreferences(
            storeOrder: target.storeOrder != baseline.storeOrder ? target.storeOrder : nil,
            storeReview: target.storeReview != baseline.storeReview ? target.storeReview : nil,
            storeStock: target.storeStock != baseline.storeStock ? target.storeStock : nil
        )
    }

    func rememberLastKnownMinAmount(from value: Decimal?) {
        guard let value, value > 0 else { return }
        lastKnownStoreOrderMinAmount = value
    }
}

extension PushNotificationPreferencesViewModel {
    /// Threshold text-field input helpers. Accepts digits from any Unicode
    /// script (ASCII, Arabic-Indic, Devanagari, etc.).
    enum StoreOrderThreshold {
        /// `true` if `s` is a positive integer string with no leading zero.
        static func isAllowedInput(_ s: String) -> Bool {
            guard !s.isEmpty else { return false }
            guard let firstDigit = s.first?.wholeNumberValue, firstDigit != 0 else { return false }
            return s.unicodeScalars.allSatisfy(CharacterSet.decimalDigits.contains)
        }

        /// Parses `input` as a non-negative integer Decimal, or `nil` for
        /// empty / invalid input.
        static func parse(_ input: String) -> Decimal? {
            let trimmed = input.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { return nil }
            var value: Decimal = 0
            for char in trimmed {
                guard let digit = char.wholeNumberValue else { return nil }
                value = value * 10 + Decimal(digit)
            }
            return value
        }

        /// Formats `amount` for display in the threshold text field as an
        /// integer string (no decimals, no thousands separator).
        static func formatInput(_ amount: Decimal?) -> String {
            guard let amount, amount > 0 else { return "" }
            let rounded = NSDecimalNumber(decimal: amount).intValue
            return String(rounded)
        }
    }
}

private extension PushNotificationPreferences {
    var isEmpty: Bool {
        storeOrder == nil && storeReview == nil && storeStock == nil
    }

    func with(storeOrder: StoreOrder) -> Self {
        .init(storeOrder: storeOrder, storeReview: storeReview, storeStock: storeStock)
    }

    func with(storeReview: StoreReview) -> Self {
        .init(storeOrder: storeOrder, storeReview: storeReview, storeStock: storeStock)
    }

    func with(storeStock: StoreStock) -> Self {
        .init(storeOrder: storeOrder, storeReview: storeReview, storeStock: storeStock)
    }
}

extension PushNotificationPreferencesViewModel {
    enum Localization {
        static let errorNoticeTitle = NSLocalizedString(
            "pushNotificationPreferencesViewModel.errorNoticeTitle",
            value: "Couldn't update notification preferences",
            comment: "Title of the notice shown when saving push notification preferences fails."
        )
        static let errorNoticeMessage = NSLocalizedString(
            "pushNotificationPreferencesViewModel.errorNoticeMessage",
            value: "Please try again.",
            comment: "Message of the notice shown when saving push notification preferences fails."
        )
    }
}
