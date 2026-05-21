import Foundation
import Observation
import Yosemite
import class WooFoundation.CurrencyFormatter
import class WooFoundation.CurrencySettings

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

    private(set) var isSaving = false

    var isStoreOrderEnabled: Bool { displayed.storeOrder?.enabled ?? false }
    var isStoreReviewEnabled: Bool { displayed.storeReview?.enabled ?? false }
    var isStoreStockEnabled: Bool { displayed.storeStock?.enabled ?? false }
    var isStoreStockLowStock: Bool { displayed.storeStock?.lowStock ?? false }
    var isStoreStockOutOfStock: Bool { displayed.storeStock?.outOfStock ?? false }
    var isStoreStockOnBackorder: Bool { displayed.storeStock?.onBackorder ?? false }

    /// `nil` means "all orders".
    var storeOrderMinAmount: Decimal? { displayed.storeOrder?.minAmount }

    var storeOrderCurrencySymbol: String {
        currencySettings.symbol(from: currencySettings.currencyCode)
    }

    /// Last positive threshold seen, used to restore the value when the user
    /// toggles "Only high-value orders" back on after switching to "All new orders".
    private(set) var lastKnownStoreOrderMinAmount: Decimal?

    static let defaultStoreOrderMinAmount: Decimal = 100

    var storeOrderDetailText: String {
        guard let amount = storeOrderMinAmount, amount > 0 else {
            return Localization.allOrders
        }
        let formatted = currencyFormatter.formatAmount(amount,
                                                       with: currencySettings.currencyCode.rawValue,
                                                       numberOfDecimals: 0) ?? ""
        return String.localizedStringWithFormat(Localization.ordersOverFormat, formatted)
    }

    /// `nil` means "all reviews"; otherwise an in-range value (1...5) is the
    /// maximum star rating that triggers a notification.
    var storeReviewMaxRating: Int? { displayed.storeReview?.maxRating }

    /// Last in-range rating seen, used to restore the value when the user
    /// toggles "Only low-rated reviews" back on after switching to "All new reviews".
    private(set) var lastKnownStoreReviewMaxRating: Int?

    static let defaultStoreReviewMaxRating: Int = 2

    var storeReviewDetailText: String {
        guard let maxRating = storeReviewMaxRating, (1...5).contains(maxRating) else {
            return Localization.allReviews
        }
        let format = maxRating == 1 ? Localization.reviewsBelowFormatSingular
                                    : Localization.reviewsBelowFormatPlural
        let count = NumberFormatter.localizedString(from: NSNumber(value: maxRating), number: .none)
        return String.localizedStringWithFormat(format, count)
    }

    var errorNotice: Notice?

    private let siteID: Int64
    private let stores: StoresManager
    private let currencyFormatter: CurrencyFormatter
    private let currencySettings: CurrencySettings

    init(siteID: Int64,
         stores: StoresManager = ServiceLocator.stores,
         currencySettings: CurrencySettings = ServiceLocator.currencySettings) {
        self.siteID = siteID
        self.stores = stores
        self.currencySettings = currencySettings
        self.currencyFormatter = CurrencyFormatter(currencySettings: currencySettings)
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
            rememberLastKnownMaxRating(from: preferences.storeReview?.maxRating)
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
        guard !isSaving else { return false }
        isSaving = true
        defer { isSaving = false }
        do {
            let server = try await withCheckedThrowingContinuation { continuation in
                stores.dispatch(NotificationAction.updatePushNotificationPreferences(siteID: siteID,
                                                                                     changes: pendingDiff) { result in
                    continuation.resume(with: result)
                })
            }
            lastSaved = server
            rememberLastKnownMinAmount(from: server.storeOrder?.minAmount)
            rememberLastKnownMaxRating(from: server.storeReview?.maxRating)
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

    /// Reverts only the new-review section of `displayed` to `lastSaved`.
    /// Other sections are left untouched — their detail screens own their
    /// own discard paths.
    func discardStoreReviewEdits() {
        displayed = PushNotificationPreferences(storeOrder: displayed.storeOrder,
                                                storeReview: lastSaved.storeReview,
                                                storeStock: displayed.storeStock)
    }

    func setStoreReviewMaxRating(_ newValue: Int?) {
        // Clamp any non-nil value to the server-supported `1...5` range; nil
        // stays nil ("all reviews").
        let normalized: Int? = {
            guard let value = newValue else { return nil }
            return min(max(value, 1), 5)
        }()
        rememberLastKnownMaxRating(from: normalized)
        displayed = displayed.with(storeReview: .init(enabled: isStoreReviewEnabled,
                                                      maxRating: normalized))
    }

    func setStoreStockEnabled(_ newValue: Bool) {
        let existing = displayed.storeStock
        displayed = displayed.with(storeStock: .init(enabled: newValue,
                                                     lowStock: existing?.lowStock,
                                                     outOfStock: existing?.outOfStock,
                                                     onBackorder: existing?.onBackorder))
    }

    func setStoreStockLowStock(_ newValue: Bool) {
        let existing = displayed.storeStock
        displayed = displayed.with(storeStock: .init(enabled: existing?.enabled,
                                                     lowStock: newValue,
                                                     outOfStock: existing?.outOfStock,
                                                     onBackorder: existing?.onBackorder))
    }

    func setStoreStockOutOfStock(_ newValue: Bool) {
        let existing = displayed.storeStock
        displayed = displayed.with(storeStock: .init(enabled: existing?.enabled,
                                                     lowStock: existing?.lowStock,
                                                     outOfStock: newValue,
                                                     onBackorder: existing?.onBackorder))
    }

    func setStoreStockOnBackorder(_ newValue: Bool) {
        let existing = displayed.storeStock
        displayed = displayed.with(storeStock: .init(enabled: existing?.enabled,
                                                     lowStock: existing?.lowStock,
                                                     outOfStock: existing?.outOfStock,
                                                     onBackorder: newValue))
    }

    /// Reverts only the stock section of `displayed` to `lastSaved`. Other
    /// sections are left untouched — their detail screens own their own
    /// discard paths.
    func discardStoreStockEdits() {
        displayed = PushNotificationPreferences(storeOrder: displayed.storeOrder,
                                                storeReview: displayed.storeReview,
                                                storeStock: lastSaved.storeStock)
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

    func rememberLastKnownMaxRating(from value: Int?) {
        guard let value, (1...5).contains(value) else { return }
        lastKnownStoreReviewMaxRating = value
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
        static let allOrders = NSLocalizedString(
            "pushNotificationPreferencesViewModel.storeOrder.allOrders",
            value: "All orders",
            comment: "Detail text for the New orders row when notifications fire for every order."
        )
        static let ordersOverFormat = NSLocalizedString(
            "pushNotificationPreferencesViewModel.storeOrder.ordersOverFormat",
            value: "Orders over %1$@",
            comment: "Detail text for the New orders row when a threshold is set. %1$@ is the formatted currency amount, e.g. $500."
        )
        static let allReviews = NSLocalizedString(
            "pushNotificationPreferencesViewModel.storeReview.allReviews",
            value: "All reviews",
            comment: "Detail text for the New reviews row when notifications fire for every review."
        )
        static let reviewsBelowFormatSingular = NSLocalizedString(
            "pushNotificationPreferencesViewModel.storeReview.reviewsBelowFormat.singular",
            value: "%1$@ star and below",
            comment: "Detail text for the New reviews row when the maximum rating is 1. %1$@ is the formatted star count."
        )
        static let reviewsBelowFormatPlural = NSLocalizedString(
            "pushNotificationPreferencesViewModel.storeReview.reviewsBelowFormat.plural",
            value: "%1$@ stars and below",
            comment: "Detail text for the New reviews row when the maximum rating is 2-5. %1$@ is the formatted star count."
        )
    }
}
