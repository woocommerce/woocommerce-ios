import SwiftUI

struct POSBookingDetailsEmptyView: View {
    @Environment(\.colorScheme) private var colorScheme

    private var iconColor: Color {
        colorScheme == .dark ? .posPrimary : .posOnSurfaceVariantLowest
    }

    private var textColor: Color {
        colorScheme == .dark ? .posOnSurface : .posOnSurfaceVariantLowest
    }

    var body: some View {
        VStack(spacing: POSSpacing.large) {
            Image(systemName: "calendar")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: Constants.iconSize, height: Constants.iconSize)
                .foregroundColor(iconColor)

            Text(Localization.noBookingSelected)
                .font(.posBodyMediumRegular())
                .foregroundStyle(textColor)
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
        "pos.bookingDetailsEmptyView.description",
        value: "Tap a booking to view its details",
        comment: "Text appearing in the booking details pane when no booking is selected."
    )
}
