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

    var selectedTab: Tab = .sale
    var isShowingCheckout: Bool = false

    // Secondary feature presentation state.
    // On iPad these drive full-screen covers from the floating menu.
    // On phone these map to tab selection.
    var isShowingOrders: Bool = false {
        didSet { if isShowingOrders { selectedTab = .orders } }
    }
    var isShowingBookings: Bool = false {
        didSet { if isShowingBookings { selectedTab = .bookings } }
    }
    var isShowingSettings: Bool = false {
        didSet { if isShowingSettings { selectedTab = .settings } }
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
