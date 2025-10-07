import SwiftUI

struct POSOrderDetailsEmptyView: View {
    var body: some View {
        VStack(spacing: 0) {
            POSPageHeaderView(
                title: Localization.title,
                backButtonConfiguration: nil
            )

            VStack {
                Spacer()

                Text(Localization.noOrderToDisplay)
                    .font(.posBodyLargeRegular())
                    .foregroundStyle(Color.posOnSurfaceVariantHighest)
                    .multilineTextAlignment(.center)

                Spacer()
            }
        }
        .background(Color.posSurface)
        .navigationBarHidden(true)
    }
}

private enum Localization {
    static let title = NSLocalizedString(
        "pos.orderDetailsEmptyView.ordersTitle",
        value: "Order",
        comment: "Title at the header for the Order Details empty view."
    )

    static let noOrderToDisplay = NSLocalizedString(
        "pos.orderDetailsEmptyView.noOrderToDisplay",
        value: "No order to display",
        comment: "Text appearing in the order details pane when there are no orders available."
    )
}

#if DEBUG
#Preview {
    POSOrderDetailsEmptyView()
}
#endif
