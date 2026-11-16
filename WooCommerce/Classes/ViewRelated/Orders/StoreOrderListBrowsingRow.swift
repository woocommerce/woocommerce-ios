import StoreDesignSystem
import SwiftUI

struct StoreOrderListBrowsingRow: View {
    let filterCount: Int
    let lastUpdatedText: String?
    let onFilterTapped: () -> Void

    var body: some View {
        VStack(spacing: StoreSpacing.s0) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .center, spacing: StoreSpacing.s3) {
                    labels
                    filterChip
                }
                VStack(alignment: .leading, spacing: StoreSpacing.s3) {
                    labels
                    filterChip
                }
            }
            .padding(.horizontal, StorePadding.p5)
            .padding(.vertical, StorePadding.p3)
            .background(.storeSurfaceBright)

            StoreDivider()
        }
    }

    private var labels: some View {
        VStack(alignment: .leading, spacing: StoreSpacing.s1) {
            Text(filterCount > 0 ? OrderListLocalization.filteredOrders : OrderListLocalization.allOrders)
                .storeTextStyle(.titleSmall.strong)
                .foregroundStyle(.storeOnSurface)
                .accessibilityAddTraits(.isHeader)
            if let lastUpdatedText {
                Text(lastUpdatedText)
                    .storeTextStyle(.bodySmall)
                    .foregroundStyle(.storeOnSurfaceVariant)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var filterChip: some View {
        StoreFilterChip(OrderListLocalization.filterTitle(count: filterCount),
                        icon: StoreIcon.BarsFilter.regular,
                        isSelected: filterCount > 0,
                        action: onFilterTapped)
            .accessibilityIdentifier("orders-filter-button")
    }
}
