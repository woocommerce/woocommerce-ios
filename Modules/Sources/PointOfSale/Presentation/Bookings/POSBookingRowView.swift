import SwiftUI
import struct Yosemite.POSBooking

struct POSBookingRowView: View {
    let booking: POSBooking
    let isSelected: Bool

    @ScaledMetric private var scale: CGFloat = 1.0
    @Environment(\.dynamicTypeSize) var dynamicTypeSize
    @Environment(\.siteTimezone) private var siteTimezone

    var body: some View {
        VStack(alignment: .leading, spacing: POSSpacing.none) {
            bookingHeaderRow
                .padding(.bottom, POSSpacing.xSmall)
            POSBookingSummaryView(booking: booking)
        }
        .padding(.horizontal, POSPadding.medium * (1 / scale))
        .padding(.vertical, POSPadding.medium * (1 / scale))
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.posSurfaceContainerLowest)
        .posItemCardBorderStyles()
        .overlay {
            if isSelected {
                RoundedRectangle(cornerRadius: POSCornerRadiusStyle.medium.value)
                    .stroke(Color.posOnSurface, lineWidth: 2)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    @ViewBuilder
    private var bookingHeaderRow: some View {
        HStack(alignment: .center) {
            Text(POSBookingSummaryView.formattedTimeRange(for: booking, siteTimezone: siteTimezone))
                .font(.posBodySmallBold())
                .foregroundStyle(Color.posOnSurface)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()

            POSBookingAvatarView(imageURL: booking.resourceImageURL, resourceName: booking.resourceName)
        }
    }

}
