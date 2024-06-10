import SwiftUI
import enum Yosemite.OrderStatusEnum

/// Shown when the site doesn't have any orders for the given order status.
/// Contains a placeholder image and text.
///
struct LastOrdersDashboardEmptyView: View {
    let orderStatus: OrderStatusEnum?

    var body: some View {
        VStack(alignment: .center, spacing: Layout.defaultSpacing) {
            Image(uiImage: .emptyOrdersImage)

            Text(message)
                .subheadlineStyle()
        }
        .padding(.all, Layout.defaultSpacing)
    }
}

private extension LastOrdersDashboardEmptyView {
    var message: String {
        guard let orderStatus else {
            return Localization.noOrders
        }
        return String.localizedStringWithFormat(Localization.noOrdersWithStatus, orderStatus.description.lowercased())
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

    enum Layout {
        static let defaultSpacing: CGFloat = 16
    }
}

struct LastOrdersDashboardEmptyView_Previews: PreviewProvider {
    static var previews: some View {
        LastOrdersDashboardEmptyView(orderStatus: .pending)
    }
}
