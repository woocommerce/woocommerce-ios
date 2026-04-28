import SwiftUI
import enum Yosemite.AnalyticsOrderDateType

/// Bottom sheet that lets the merchant choose which order date type the Performance card uses.
/// Backed by the `woocommerce_date_type` site setting.
struct PerformanceCardOrderTypeBottomSheet: View {
    @ObservedObject var viewModel: StorePerformanceViewModel
    @Environment(\.dismiss) private var dismiss

    /// The order type whose update is currently in flight, if any.
    /// Used to render an inline progress indicator next to the row being saved
    /// and to disable other rows while a save is in progress.
    @State private var updatingType: AnalyticsOrderDateType?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                Text(Localization.title)
                    .font(.title3.weight(.semibold))
                    .padding(.top, Layout.titleTopPadding)

                Text(Localization.description)
                    .font(.body.weight(.regular))
                    .padding(.top, Layout.titleToDescriptionSpacing)

                VStack(alignment: .leading, spacing: Layout.rowSpacing) {
                    ForEach(AnalyticsOrderDateType.allCases, id: \.rawValue) { type in
                        Button {
                            handleSelection(of: type)
                        } label: {
                            row(for: type)
                        }
                        .buttonStyle(.plain)
                        .disabled(updatingType != nil)
                        .accessibilityIdentifier("performance-order-type-\(type.rawValue)")
                    }
                }
                .padding(.top, Layout.descriptionToOptionsSpacing)

                if viewModel.orderTypeUpdateError != nil {
                    HStack(spacing: Layout.errorSpacing) {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundStyle(Color(.error))
                        Text(Localization.updateError)
                            .footnoteStyle(isError: true)
                    }
                    .padding(.top, Layout.errorTopSpacing)
                }

                Text(Localization.footer)
                    .font(.footnote.weight(.regular))
                    .foregroundStyle(.secondary)
                    .padding(.top, Layout.optionsToFooterSpacing)
            }
            .padding(.horizontal, Layout.horizontalPadding)
            .padding(.bottom, Layout.bottomPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .presentationDetents([.fraction(Layout.preferredDetentFraction), .large])
        .presentationDragIndicator(.visible)
    }

    private func handleSelection(of type: AnalyticsOrderDateType) {
        // Tapping the currently-selected row just dismisses; nothing to save.
        if viewModel.orderType == type {
            dismiss()
            return
        }
        Task { @MainActor in
            updatingType = type
            await viewModel.didSelectOrderType(type)
            updatingType = nil
            // Dismiss only if the save actually took effect on the view model.
            // If the save failed (or the server returned a value that doesn't match), the sheet stays
            // open so the inline error block remains visible.
            if viewModel.orderType == type {
                dismiss()
            }
        }
    }

    @ViewBuilder
    private func row(for type: AnalyticsOrderDateType) -> some View {
        let isSelected = viewModel.orderType == type
        let isUpdating = updatingType == type
        HStack(alignment: .top, spacing: Layout.rowCheckmarkSpacing) {
            VStack(alignment: .leading, spacing: Layout.rowTitleSubtitleSpacing) {
                Text(type.localizedTitle)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)
                Text(type.localizedDescription)
                    .font(.subheadline.weight(.regular))
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            trailingAccessory(isSelected: isSelected, isUpdating: isUpdating)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private func trailingAccessory(isSelected: Bool, isUpdating: Bool) -> some View {
        if isUpdating {
            ProgressView()
                .progressViewStyle(.circular)
        } else if isSelected {
            Image(uiImage: .checkmarkStyledImage)
        }
    }
}

extension AnalyticsOrderDateType {
    /// User-facing title for the Performance card order label and bottom sheet rows.
    var localizedTitle: String {
        switch self {
        case .paid:
            return PerformanceCardOrderTypeBottomSheet.Localization.paidTitle
        case .allOrders:
            return PerformanceCardOrderTypeBottomSheet.Localization.placedTitle
        case .completed:
            return PerformanceCardOrderTypeBottomSheet.Localization.completedTitle
        }
    }

    /// Short description shown beneath each option in the bottom sheet.
    var localizedDescription: String {
        switch self {
        case .paid:
            return PerformanceCardOrderTypeBottomSheet.Localization.paidDescription
        case .allOrders:
            return PerformanceCardOrderTypeBottomSheet.Localization.placedDescription
        case .completed:
            return PerformanceCardOrderTypeBottomSheet.Localization.completedDescription
        }
    }
}

extension PerformanceCardOrderTypeBottomSheet {
    enum Layout {
        static let horizontalPadding: CGFloat = 16
        static let titleTopPadding: CGFloat = 29
        static let titleToDescriptionSpacing: CGFloat = 10
        static let descriptionToOptionsSpacing: CGFloat = 24
        static let optionsToFooterSpacing: CGFloat = 24
        static let bottomPadding: CGFloat = 24
        static let rowSpacing: CGFloat = 20
        static let rowTitleSubtitleSpacing: CGFloat = 3
        static let rowCheckmarkSpacing: CGFloat = 12
        static let errorSpacing: CGFloat = 8
        static let errorTopSpacing: CGFloat = 16
        /// Custom default detent — a bit bigger than `.medium` so that the entire
        /// content (including the footer text) is visible without forcing a swipe to `.large`.
        static let preferredDetentFraction: CGFloat = 0.65
    }

    enum Localization {
        static let title = NSLocalizedString(
            "performanceCardOrderTypeBottomSheet.title.v2",
            value: "Order date type",
            comment: "Title of the bottom sheet that lets the merchant choose which order date type to include in dashboard analytics."
        )
        static let description = NSLocalizedString(
            "performanceCardOrderTypeBottomSheet.description.v2",
            value: "Choose which orders to include in your performance metrics for the selected time range.",
            comment: "Description shown below the title of the order type bottom sheet on the dashboard Performance card."
        )
        static let footer = NSLocalizedString(
            "performanceCardOrderTypeBottomSheet.footer",
            value: "This is a store-wide setting, which also controls the “Date type” option in WooCommerce admin analytics settings.",
            comment: "Clarification text shown below the order type options on the dashboard Performance card bottom sheet."
        )
        static let updateError = NSLocalizedString(
            "performanceCardOrderTypeBottomSheet.updateError",
            value: "Couldn't update the order type. Please try again.",
            comment: "Inline error shown when saving the analytics order type setting fails."
        )
        static let paidTitle = NSLocalizedString(
            "performanceCardOrderTypeBottomSheet.paidTitle",
            value: "Paid orders",
            comment: "Order type option that counts orders by the date they were paid."
        )
        static let paidDescription = NSLocalizedString(
            "performanceCardOrderTypeBottomSheet.paidDescription.v2",
            value: "Count orders on the date the order was paid.",
            comment: "Description of the paid orders option in the dashboard Performance card bottom sheet."
        )
        static let placedTitle = NSLocalizedString(
            "performanceCardOrderTypeBottomSheet.placedTitle",
            value: "Placed orders",
            comment: "Order type option that counts orders by the date they were placed (created)."
        )
        static let placedDescription = NSLocalizedString(
            "performanceCardOrderTypeBottomSheet.placedDescription",
            value: "Count orders on the date they were placed or created.",
            comment: "Description of the placed orders option in the dashboard Performance card bottom sheet."
        )
        static let completedTitle = NSLocalizedString(
            "performanceCardOrderTypeBottomSheet.completedTitle",
            value: "Completed orders",
            comment: "Order type option that counts orders by the date they were marked as completed."
        )
        static let completedDescription = NSLocalizedString(
            "performanceCardOrderTypeBottomSheet.completedDescription.v2",
            value: "Count orders on the date they were marked as completed.",
            comment: "Description of the completed orders option in the dashboard Performance card bottom sheet."
        )
    }
}

#Preview("Default") {
    Color.gray
        .sheet(isPresented: .constant(true)) {
            PerformanceCardOrderTypeBottomSheet(
                viewModel: StorePerformanceViewModel(siteID: 123, usageTracksEventEmitter: .init())
            )
        }
}
