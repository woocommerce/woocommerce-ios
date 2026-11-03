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
            return Localization.noOrders
        }
        return String.localizedStringWithFormat(Localization.noOrdersWithStatus, statusName.lowercased())
    }

    enum Localization {
        static let noOrders = NSLocalizedString(
            "lastOrdersDashboardEmptyView.noOrders",
            value: "Waiting for your first order",
            comment: "Message when there are no orders found."
        )
        static let noOrdersWithStatus = NSLocalizedString(
            "lastOrdersDashboardEmptyView.noOrdersWithStatus",
            value: "No %@ orders found",
            comment: "Message when there are no orders found for a selected order status. The %@ is a placeholder for the order status selected by the user."
        )
    }
}

#Preview {
    StoreLastOrdersDashboardEmptyView(statusName: "Pending payment")
}
