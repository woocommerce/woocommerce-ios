import SwiftUI

struct POSBookingDetailsEmptyView: View {
    var body: some View {
        VStack(spacing: POSSpacing.large) {
            PointOfSaleAssets.noBookings.decorativeImage
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: Constants.iconSize, height: Constants.iconSize)
                .foregroundColor(.posOnSurface)

            Text(Localization.noBookingSelected)
                .font(.posBodyMediumRegular())
                .foregroundStyle(Color.posOnSurfaceVariantLowest)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.posSurface)
        .navigationBarHidden(true)
    }
}

private enum Constants {
    static let iconSize: CGFloat = 88
}

private enum Localization {
    static let noBookingSelected = NSLocalizedString(
        "pos.bookingDetailsEmptyView.descrition",
        value: "Tap a booking to view its details",
        comment: "Text appearing in the booking details pane when no booking is selected."
    )
}
