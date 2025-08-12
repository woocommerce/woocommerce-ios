import Foundation

@available(iOS 17.0, *)
protocol PointOfSaleViewStateResettable {
    /// Resets all view state to its default values.
    /// This should be called when starting a new cart to ensure the UI returns to its initial state.
    func reset()
}

/// Coordinates view-specific state for the Point of Sale interface.
/// This coordinator manages UI state that needs to persist across the POS experience
/// but should be reset when starting a new cart/order.
@available(iOS 17.0, *)
@Observable final class PointOfSaleViewStateCoordinator: PointOfSaleViewStateResettable {
    /// The currently selected item list type, shown when building the cart.
    /// When we reset, the non-searched products list is shown for the new cart.
    var selectedItemListType: ItemListType = .products(search: false)

    /// The current search term being used to filter items.
    /// This is used when `selectedItemListType` is in search mode.
    /// When we reset, the search term is cleared for the new cart.
    var searchTerm: String = ""

    /// Whether the settings view should be displayed full-screen.
    /// When true, the main POS interface is hidden and settings are shown instead.
    var showingSettings: Bool = false

    /// Shows the settings view full-screen.
    func showSettings() {
        showingSettings = true
    }

    /// Hides the settings view and returns to the main POS interface.
    func hideSettings() {
        showingSettings = false
    }

    /// Resets all view state to its default values.
    /// This should be called when starting a new cart to ensure the UI returns to its initial state.
    func reset() {
        selectedItemListType = .products(search: false)
        searchTerm = ""
        showingSettings = false
    }
}
