import SwiftUI
import struct Yosemite.POSBooking

struct POSBookingRowView: View {
    let booking: POSBooking
    let isSelected: Bool

    @ScaledMetric private var scale: CGFloat = 1.0
    @Environment(\.dynamicTypeSize) var dynamicTypeSize

    private var lifecycleStatus: POSBookingLifecycleStatus {
        POSBookingLifecycleStatus(bookingStatus: booking.status)
    }

    private var paymentStatus: POSBookingPaymentStatus {
        POSBookingPaymentStatus(bookingStatus: booking.status)
    }

    private var attendanceDisplay: POSBookingAttendanceDisplay {
        POSBookingAttendanceDisplay(attendanceStatus: booking.attendanceStatus)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: POSSpacing.none) {
            bookingHeaderRow
                .padding(.bottom, POSSpacing.xSmall)
            bookingDetailsRow
                .padding(.bottom, POSSpacing.small)
            statusBadges
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
            Text(formattedTimeRange)
                .font(.posBodySmallBold())
                .foregroundStyle(Color.posOnSurface)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()

            POSBookingAvatarView(imageURL: booking.resourceImageURL)
        }
    }

    @ViewBuilder
    private var bookingDetailsRow: some View {
        Text(detailsText)
            .font(.posBodySmallRegular())
            .foregroundStyle(Color.posOnSurfaceVariantHighest)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var statusBadges: some View {
        HStack(spacing: POSSpacing.small) {
            if lifecycleStatus == .cancelled {
                POSBookingBadgeView(title: lifecycleStatus.localizedTitle,
                                    textColor: lifecycleStatus.textColor,
                                    backgroundColor: lifecycleStatus.backgroundColor)
            } else {
                POSBookingBadgeView(title: attendanceDisplay.localizedTitle,
                                    textColor: attendanceDisplay.textColor,
                                    backgroundColor: attendanceDisplay.backgroundColor)
            }
            POSBookingBadgeView(title: paymentStatus.localizedTitle,
                                textColor: paymentStatus.textColor,
                                backgroundColor: paymentStatus.backgroundColor)
        }
    }

    private var accessibilityLabel: String {
        let timeRange = Localization.timeRangeAccessibilityLabel(
            start: DateFormatter.timeFormatter.string(from: booking.startDate),
            end: DateFormatter.timeFormatter.string(from: booking.endDate)
        )

        let customerDisplayName = booking.customerName ?? booking.customerEmail

        var parts = [timeRange, booking.serviceName, customerDisplayName].compactMap { $0 }.filter { !$0.isEmpty }

        if lifecycleStatus == .cancelled {
            parts.append(lifecycleStatus.localizedTitle)
        } else {
            parts.append(attendanceDisplay.localizedTitle)
        }
        parts.append(paymentStatus.localizedTitle)

        return parts.joined(separator: ", ")
    }

    private var formattedTimeRange: String {
        let dateString = DateFormatter.shortDateFormatter.string(from: booking.startDate)
        let timeFormatter = DateFormatter.timeFormatter
        let startTime = timeFormatter.string(from: booking.startDate)
        let endTime = timeFormatter.string(from: booking.endDate)
        return "\(dateString), \(startTime)-\(endTime)"
    }

    private var detailsText: String {
        let customerDisplayName = booking.customerName ?? booking.customerEmail
        let parts = [booking.serviceName, customerDisplayName].compactMap { $0 }.filter { !$0.isEmpty }
        return parts.joined(separator: " \u{00B7} ")
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
    static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()

    static let shortDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("MM/dd/yyyy")
        return formatter
    }()
}
