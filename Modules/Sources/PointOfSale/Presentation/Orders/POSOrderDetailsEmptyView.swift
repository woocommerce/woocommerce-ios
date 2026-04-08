import SwiftUI

struct POSOrderDetailsEmptyView: View {
    var body: some View {
        ZStack {
            VStack {
                POSPageHeaderView(
                    title: Localization.title,
                    backButtonConfiguration: nil
                )
                Spacer()
            }

            VStack {
                Spacer()

                PointOfSaleAssets.noOrders.decorativeImage
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: Constants.iconSize, height: Constants.iconSize)
                    .foregroundColor(.posOnSurface)

                Spacer().frame(height: POSSpacing.medium)

                Text(Localization.noOrderSelected)
                    .font(.posBodyLargeRegular())
                    .foregroundStyle(Color.posOnSurface)
                    .multilineTextAlignment(.center)

                Spacer()
            }
        }
        .background(Color.posSurface)
        .navigationBarHidden(true)
    }
}

private enum Constants {
    static let iconSize: CGFloat = 88
}

private enum Localization {
    static let title = NSLocalizedString(
        "pos.orderDetailsEmptyView.ordersTitle",
        value: "Order",
        comment: "Title at the header for the Order Details empty view."
    )

    static let noOrderSelected = NSLocalizedString(
        "pos.orderDetailsEmptyView.noOrderSelected",
        value: "No order selected.",
        comment: "Text appearing in the order details pane when no order is selected."
    )
}

#if DEBUG
#Preview {
    POSOrderDetailsEmptyView()
}
#endif
