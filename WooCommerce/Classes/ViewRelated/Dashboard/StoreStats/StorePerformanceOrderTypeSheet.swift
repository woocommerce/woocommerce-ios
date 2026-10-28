import StoreDesignSystem
import SwiftUI
import enum Yosemite.AnalyticsOrderDateType

struct StorePerformanceOrderTypeSheet: View {
    @ObservedObject var viewModel: StorePerformanceViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: StoreSpacing.s0) {
            VStack(alignment: .leading, spacing: StoreSpacing.s4) {
                Text(Localization.title)
                    .storeTextStyle(.titleLarge.strong)
                    .foregroundStyle(.storeOnSurface)
                Text(Localization.description)
                    .storeTextStyle(.bodyLarge)
                    .foregroundStyle(.storeOnSurfaceVariant)
            }
            .padding(.horizontal, StorePadding.p7)
            .padding(.vertical, StorePadding.p5)

            StoreRadioGroup(
                selection: Binding(get: { viewModel.orderType }, set: select),
                options: AnalyticsOrderDateType.allCases,
                rowSpacing: StoreSpacing.s0
            ) { type in
                HStack(spacing: StoreSpacing.s4) {
                    VStack(alignment: .leading, spacing: StoreSpacing.s2) {
                        Text(type.localizedTitle)
                            .storeTextStyle(.bodyLarge.emphasized)
                            .foregroundStyle(.storeOnSurface)
                        Text(type.localizedDescription)
                            .storeTextStyle(.bodyMedium)
                            .foregroundStyle(.storeOnSurfaceVariant)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    if viewModel.updatingOrderType == type {
                        ProgressView().tint(.storePrimary)
                    }
                }
                .padding(.vertical, StorePadding.p5)
                .accessibilityIdentifier("performance-order-type-\(type.rawValue)")
            }
            .disabled(viewModel.updatingOrderType != nil)
            .padding(.horizontal, StorePadding.p7)

            if viewModel.orderTypeUpdateError != nil {
                Text(Localization.updateError)
                    .storeTextStyle(.bodyMedium)
                    .foregroundStyle(.storeOnErrorContainer)
                    .padding(StorePadding.p4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.storeErrorContainer)
                    .clipShape(.rect(cornerRadius: StoreRadius.medium))
                    .padding(.horizontal, StorePadding.p7)
                    .padding(.top, StorePadding.p3)
            }

            Text(Localization.footer)
                .storeTextStyle(.bodySmall)
                .foregroundStyle(.storeOnSurfaceVariantLowest)
                .padding(.horizontal, StorePadding.p7)
                .padding(.vertical, StorePadding.p5)
        }
    }

    private func select(_ type: AnalyticsOrderDateType) {
        Task { @MainActor in
            if await viewModel.handleOrderTypeSelection(type) {
                dismiss()
            }
        }
    }
}

private extension StorePerformanceOrderTypeSheet {
    enum Localization {
        static let title = NSLocalizedString(
            "performanceCardOrderTypeBottomSheet.title.v2",
            value: "Order date type",
            comment: "Title of the order date type sheet"
        )
        static let description = NSLocalizedString(
            "performanceCardOrderTypeBottomSheet.description.v2",
            value: "Choose which orders to include in your performance metrics for the selected time range.",
            comment: "Description of the order date type sheet"
        )
        static let footer = NSLocalizedString(
            "performanceCardOrderTypeBottomSheet.footer",
            value: "This is a store-wide setting, which also controls the “Date type” option in WooCommerce admin analytics settings.",
            comment: "Footer of the order date type sheet"
        )
        static let updateError = NSLocalizedString(
            "performanceCardOrderTypeBottomSheet.updateError",
            value: "Couldn't update the order type. Please try again.",
            comment: "Error shown when saving the order date type fails"
        )
    }
}

#Preview {
    StoreSheet {
        StorePerformanceOrderTypeSheet(
            viewModel: StorePerformanceViewModel(siteID: 123, usageTracksEventEmitter: .init())
        )
    }
}
