import Foundation

struct ItemListViewHelper {
    /// Whether the products list should show the entry row that opens the
    /// custom amount form.
    ///
    /// Custom amounts only make sense while the merchant is building an order in the
    /// products tab. The Coupons tab and the search surface reuse the same list view
    /// for unrelated content, and the row is hidden during checkout to keep the
    /// finalizing UI focused.
    func shouldShowCustomAmountEntryRow(itemListType: ItemListType,
                                        isCustomAmountsFeatureEnabled: Bool,
                                        orderStage: PointOfSaleOrderStage,
                                        isSearching: Bool) -> Bool {
        guard case .products = itemListType else { return false }
        guard isCustomAmountsFeatureEnabled else { return false }
        guard orderStage == .building else { return false }
        return !isSearching
    }
}
