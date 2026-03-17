import Foundation

/// Shared navigation state that survives size-class transitions.
/// Both the iPad dashboard and phone root view read from this model,
/// so shrinking an iPad split view preserves the user's place.
@Observable
@MainActor
final class POSNavigationModel: @unchecked Sendable {

    nonisolated init() {}

    enum Tab: Hashable {
        case sale
        case orders
        case bookings
        case settings
    }

    /// The active tab on phone. Setting this also syncs the isShowing* flags
    /// so that transitioning from compact to regular preserves the visible feature.
    var selectedTab: Tab = .sale {
        didSet {
            guard selectedTab != oldValue else { return }
            syncShowingFlags(for: selectedTab)
        }
    }
    var isShowingCheckout: Bool = false

    // Secondary feature presentation state.
    // On iPad these drive full-screen covers from the floating menu.
    // On phone these map to tab selection.
    // Both directions must stay in sync for size-class transitions.
    var isShowingOrders: Bool = false {
        didSet { if isShowingOrders { selectedTab = .orders } }
    }
    var isShowingBookings: Bool = false {
        didSet { if isShowingBookings { selectedTab = .bookings } }
    }
    var isShowingSettings: Bool = false {
        didSet { if isShowingSettings { selectedTab = .settings } }
    }

    /// Syncs the isShowing* flags to match the selected tab.
    /// Called when the tab changes (e.g. user taps a tab on phone).
    private func syncShowingFlags(for tab: Tab) {
        isShowingOrders = (tab == .orders)
        isShowingBookings = (tab == .bookings)
        isShowingSettings = (tab == .settings)
    }

    func showCheckout() {
        isShowingCheckout = true
    }

    func dismissCheckout() {
        isShowingCheckout = false
    }

    /// Called after payment success — dismisses checkout and returns to the sale tab.
    func startNewOrder() {
        isShowingCheckout = false
        isShowingOrders = false
        isShowingBookings = false
        isShowingSettings = false
        selectedTab = .sale
    }
}
