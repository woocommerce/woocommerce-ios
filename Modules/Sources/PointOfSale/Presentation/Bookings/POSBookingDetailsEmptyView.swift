import SwiftUI

struct POSBookingDetailsEmptyView: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: POSSpacing.large) {
            PointOfSaleAssets.noBookings.decorativeImage
                .renderingMode(iconRenderingMode)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: Constants.iconSize, height: Constants.iconSize)
                .foregroundColor(iconTintColor)

            Text(Localization.noBookingSelected)
                .font(.posBodyMediumRegular())
                .foregroundStyle(Color.posOnSurfaceVariantLowest)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.posSurface)
        .navigationBarHidden(true)
    }

    private var iconRenderingMode: Image.TemplateRenderingMode {
        colorScheme == .dark ? .template : .original
    }

    private var iconTintColor: Color? {
        colorScheme == .dark ? .posPrimary : nil
    }
}

private enum Constants {
    static let iconSize: CGFloat = 88
}

private enum Localization {
    static let noBookingSelected = NSLocalizedString(
        "pos.bookingDetailsEmptyView.description",
        value: "Tap a booking to view its details",
        comment: "Text appearing in the booking details pane when no booking is selected."
    )
}
