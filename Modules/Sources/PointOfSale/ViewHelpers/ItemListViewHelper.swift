import Foundation

struct ItemListViewHelper {
    /// Whether the products list should show the entry row that opens the
    /// custom amount form.
    ///
    /// Custom amounts only make sense in the products tab. The Coupons tab and the
    /// search surface reuse the same list view for unrelated content, so the row
    /// is gated to non-searching products.
    ///
    /// `orderStage` is intentionally not part of this decision: at `.finalizing`
    /// the products list slides off-screen via the dashboard offset (or is replaced
    /// entirely on phone), so hiding the row here was redundant and produced a
    /// visible flash — the row vanished synchronously while the slide animation
    /// was still running, leaving an empty slot at the top of the list mid-transition.
    func shouldShowCustomAmountEntryRow(itemListType: ItemListType,
                                        isCustomAmountsFeatureEnabled: Bool,
                                        isSearching: Bool) -> Bool {
        guard case .products = itemListType else { return false }
        guard isCustomAmountsFeatureEnabled else { return false }
        return !isSearching
    }
}
