import StoreDesignSystem
import SwiftUI
import enum Yosemite.AnalyticsOrderDateType

struct StorePerformanceOrderTypeSheet: View {
    @ObservedObject var viewModel: StorePerformanceViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: StoreSpacing.s0) {
            StoreDashboardSheetHeader(
                title: PerformanceCardOrderTypeBottomSheet.Localization.title,
                description: PerformanceCardOrderTypeBottomSheet.Localization.description
            )
            .padding(.horizontal, StorePadding.p7)

            Spacer().frame(height: StoreSpacing.s7 + StoreSpacing.s2)

            VStack(alignment: .leading, spacing: StoreSpacing.s0) {
                ForEach(AnalyticsOrderDateType.allCases, id: \.rawValue) { type in
                    StoreDashboardSheetOptionRow(
                        title: type.localizedTitle,
                        description: type.localizedDescription,
                        isSelected: viewModel.orderType == type,
                        isLoading: viewModel.updatingOrderType == type,
                        accessibilityIdentifier: "performance-order-type-\(type.rawValue)",
                        action: { select(type) }
                    )
                }
            }
            .disabled(viewModel.updatingOrderType != nil)
            .padding(.horizontal, StorePadding.p7)

            if viewModel.orderTypeUpdateError != nil {
                Text(PerformanceCardOrderTypeBottomSheet.Localization.updateError)
                    .storeTextStyle(.bodyMedium)
                    .foregroundStyle(.storeOnErrorContainer)
                    .padding(.horizontal, StorePadding.p3)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.storeErrorContainer)
                    .clipShape(.rect(cornerRadius: StoreRadius.medium))
                    .padding(.horizontal, StorePadding.p7)
                    .padding(.vertical, StorePadding.p3)
            }

            Spacer().frame(height: StoreSpacing.s7)

            Text(PerformanceCardOrderTypeBottomSheet.Localization.footer)
                .storeTextStyle(.bodySmall)
                .foregroundStyle(.storeOnSurface)
                .padding(.horizontal, StorePadding.p7)

            Spacer().frame(height: StoreSpacing.s8)
        }
        .padding(.top, StorePadding.p5)
    }

    private func select(_ type: AnalyticsOrderDateType) {
        Task { @MainActor in
            if await viewModel.handleOrderTypeSelection(type) {
                dismiss()
            }
        }
    }
}

#Preview {
    StoreSheet {
        StorePerformanceOrderTypeSheet(
            viewModel: StorePerformanceViewModel(siteID: 123, usageTracksEventEmitter: .init())
        )
    }
}
