import StoreDesignSystem
import SwiftUI

struct StoreOrderListFilterChip: View {
    let state: StoreOrderListHeaderState
    let action: () -> Void

    var body: some View {
        StoreFilterChip(state.filterButtonTitle,
                        icon: StoreIcon.BarsFilter.regular,
                        isSelected: state.activeFilterCount > 0,
                        action: action)
            .accessibilityIdentifier("orders-filter-button")
    }
}
