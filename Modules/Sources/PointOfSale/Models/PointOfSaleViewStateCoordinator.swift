import Foundation

protocol PointOfSaleViewStateResettable {
    /// Resets all view state to its default values.
    /// This should be called when starting a new cart to ensure the UI returns to its initial state.
    func reset()
}

/// Coordinates view-specific state for the Point of Sale interface.
/// This coordinator manages UI state that needs to persist across the POS experience
/// but should be reset when starting a new cart/order.
@Observable final class PointOfSaleViewStateCoordinator: PointOfSaleViewStateResettable {
    /// The currently selected item list type, shown when building the cart.
    /// When we reset, the non-searched products list is shown for the new cart.
    var selectedItemListType: ItemListType = .products(search: false)

    /// The current search term being used to filter items.
    /// This is used when `selectedItemListType` is in search mode.
    /// When we reset, the search term is cleared for the new cart.
    var searchTerm: String = ""

    /// Resets all view state to its default values.
    /// This should be called when starting a new cart to ensure the UI returns to its initial state.
    func reset() {
        selectedItemListType = .products(search: false)
        searchTerm = ""
    }
}
