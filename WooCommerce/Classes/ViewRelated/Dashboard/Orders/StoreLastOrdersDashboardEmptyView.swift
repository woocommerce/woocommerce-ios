import StoreDesignSystem
import SwiftUI

/// Shown when the site doesn't have any orders for the given order status.
/// Contains a placeholder image and text.
///
struct StoreLastOrdersDashboardEmptyView: View {
    /// Server-provided display name of the selected status, or `nil` when no status is selected.
    let statusName: String?

    var body: some View {
        VStack(alignment: .center, spacing: StoreSpacing.s5) {
            Image(uiImage: .boxesImage)
                .accessibilityHidden(true)

            Text(message)
                .storeTextStyle(.titleLarge.strong)
                .foregroundStyle(.storeOnSurface)
                .multilineTextAlignment(.center)
        }
        .padding(StorePadding.p5)
        .frame(maxWidth: .infinity)
    }
}

private extension StoreLastOrdersDashboardEmptyView {
    var message: String {
        guard let statusName else {
            return LastOrdersDashboardEmptyView.Localization.noOrders
        }
        return String.localizedStringWithFormat(LastOrdersDashboardEmptyView.Localization.noOrdersWithStatus, statusName.lowercased())
    }
}

#Preview {
    StoreLastOrdersDashboardEmptyView(statusName: "Pending payment")
}
