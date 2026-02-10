import SwiftUI

struct POSBookingDetailsEmptyView: View {
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

                Text(Localization.noBookingSelected)
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
        "pos.bookingDetailsEmptyView.bookingTitle",
        value: "Booking",
        comment: "Title at the header for the Booking Details empty view."
    )

    static let noBookingSelected = NSLocalizedString(
        "pos.bookingDetailsEmptyView.noBookingSelected",
        value: "No booking selected.",
        comment: "Text appearing in the booking details pane when no booking is selected."
    )
}
