import StoreDesignSystem
import SwiftUI
import Yosemite

struct StoreOrderListRow: View {
    let row: StoreOrderListAdapter.OrderRow
    let isSelected: Bool
    let onSelect: () -> Void
    let onAppear: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: StoreSpacing.s3) {
                Text(row.cellViewModel.dateCreated)
                    .storeTextStyle(.bodySmall)
                    .foregroundStyle(.storeOnSurfaceVariant)
                    .lineLimit(1)

                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .firstTextBaseline, spacing: StoreSpacing.s5) {
                        Text(row.cellViewModel.title)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        total(maxWidth: nil, alignment: .trailing)
                    }
                    VStack(alignment: .leading, spacing: StoreSpacing.s3) {
                        Text(row.cellViewModel.title)
                        total(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .storeTextStyle(.bodyLarge)
                .foregroundStyle(.storeOnSurface)

                ViewThatFits(in: .horizontal) {
                    HStack(spacing: StoreSpacing.s2) {
                        badges
                    }
                    VStack(alignment: .leading, spacing: StoreSpacing.s2) {
                        badges
                    }
                }
            }
            .padding(.horizontal, StorePadding.p5)
            .padding(.top, StorePadding.p4)
            .padding(.bottom, StorePadding.p5)
            .frame(maxWidth: .infinity, minHeight: Constants.minimumHeight, alignment: .leading)
            .background(isSelected ? Color.storeTintLayerPrimaryContainerOpacity16 : Color.storeSurface)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("order-row-\(row.id)")
        .onAppear(perform: onAppear)
    }

    private func total(maxWidth: CGFloat?, alignment: Alignment) -> some View {
        Text(row.cellViewModel.total ?? "")
            .lineLimit(1)
            .frame(maxWidth: maxWidth, alignment: alignment)
    }

    @ViewBuilder
    private var badges: some View {
        StoreBadge(row.cellViewModel.statusString,
                   tone: row.cellViewModel.status.storeBadgeTone)
        if row.cellViewModel.salesChannel == .pointOfSale,
           let salesChannel = row.cellViewModel.salesChannel {
            StoreBadge(salesChannel.description,
                       tone: .custom(background: .storePrimaryContainer,
                                     foreground: .storeOnPrimaryContainer))
        }
    }
}

private extension StoreOrderListRow {
    enum Constants {
        static let minimumHeight = StorePadding.p12 + StorePadding.p8
    }
}
