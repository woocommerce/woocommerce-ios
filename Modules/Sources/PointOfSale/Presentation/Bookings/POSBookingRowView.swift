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
        .accessibilityLabel(accessibilityLabel)
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

    private var accessibilityLabel: String {
        let formatter = DateFormatter.posAccessibilityTimeFormatter(timeZone: siteTimezone)
        let timeRange = Localization.timeRangeAccessibilityLabel(
            start: formatter.string(from: booking.startDate),
            end: formatter.string(from: booking.endDate)
        )

        let customerDisplayName = booking.customerName ?? booking.customerEmail

        var parts = [timeRange, booking.serviceName, customerDisplayName].compactMap { $0 }.filter { !$0.isEmpty }

        if booking.lifecycleStatus == .cancelled {
            parts.append(booking.lifecycleStatus.localizedTitle)
        } else {
            parts.append(booking.attendanceDisplay.localizedTitle)
        }
        parts.append(booking.paymentStatus.localizedTitle)

        return parts.joined(separator: ", ")
    }
}

private enum Localization {
    static func timeRangeAccessibilityLabel(start: String, end: String) -> String {
        let format = NSLocalizedString(
            "pos.bookingListView.bookingRow.accessibilityLabel.timeRange",
            value: "%1$@ to %2$@",
            comment: "Time range for booking row accessibility. %1$@ is start time, %2$@ is end time."
        )
        return String(format: format, start, end)
    }
}

private extension DateFormatter {
    static func posAccessibilityTimeFormatter(timeZone: TimeZone) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        formatter.timeZone = timeZone
        return formatter
    }
}
