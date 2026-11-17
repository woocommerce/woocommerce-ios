import StoreDesignSystem
import SwiftUI
import Yosemite

struct StoreOrderListRow: View {
    let viewModel: OrderListCellViewModel
    let isSelected: Bool

    var body: some View {
        VStack(spacing: StoreSpacing.s0) {
            VStack(alignment: .leading, spacing: StoreSpacing.s3) {
                Text(viewModel.dateCreated)
                    .storeTextStyle(.bodySmall)
                    .foregroundStyle(.storeOnSurfaceVariant)
                    .lineLimit(1)

                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .firstTextBaseline, spacing: StoreSpacing.s3) {
                        Text(viewModel.orderNumber)
                            .lineLimit(1)
                        Text(viewModel.customerName)
                            .lineLimit(1)
                            .layoutPriority(1)
                        Spacer(minLength: StoreSpacing.s5)
                        Text(viewModel.total ?? "")
                            .lineLimit(1)
                    }

                    VStack(alignment: .leading, spacing: StoreSpacing.s3) {
                        HStack(spacing: StoreSpacing.s3) {
                            Text(viewModel.orderNumber)
                                .lineLimit(1)
                            Text(viewModel.customerName)
                                .lineLimit(2)
                        }
                        Text(viewModel.total ?? "")
                            .lineLimit(1)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }
                .storeTextStyle(.bodyLarge)

                ViewThatFits(in: .horizontal) {
                    HStack(spacing: StoreSpacing.s2) {
                        StoreBadge(viewModel.statusString,
                                   tone: StoreOrderListBadgePalette.statusTone(for: viewModel.status))
                        if viewModel.salesChannel == .pointOfSale {
                            StoreBadge(viewModel.salesChannel?.description ?? "",
                                       tone: StoreOrderListBadgePalette.pointOfSaleTone)
                        }
                    }

                    VStack(alignment: .leading, spacing: StoreSpacing.s2) {
                        StoreBadge(viewModel.statusString,
                                   tone: StoreOrderListBadgePalette.statusTone(for: viewModel.status))
                        if viewModel.salesChannel == .pointOfSale {
                            StoreBadge(viewModel.salesChannel?.description ?? "",
                                       tone: StoreOrderListBadgePalette.pointOfSaleTone)
                        }
                    }
                }
            }
            .foregroundStyle(.storeOnSurface)
            .padding(.horizontal, StorePadding.p5)
            .padding(.top, StorePadding.p4)
            .padding(.bottom, StorePadding.p5)
            .frame(maxWidth: .infinity,
                   minHeight: Constants.minimumRowHeight,
                   alignment: .leading)

            StoreDivider(variant: .inset)
        }
        .background(isSelected ? Color.storeTintLayerPrimaryContainerOpacity16 : Color.storeSurfaceBright)
    }
}

private extension StoreOrderListRow {
    enum Constants {
        /// Matches Android's 96-point row floor using design-system dimensions only.
        static let minimumRowHeight = StoreSize.minimumTapTarget * 2 + StoreSpacing.s3
    }
}
