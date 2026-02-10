import SwiftUI
import struct Yosemite.POSBooking

struct POSBookingRowView: View {
    let booking: POSBooking
    let isSelected: Bool

    @ScaledMetric private var scale: CGFloat = 1.0
    @Environment(\.dynamicTypeSize) var dynamicTypeSize

    private var minHeight: CGFloat {
        min(Constants.bookingCardMinHeight * scale, Constants.maximumBookingCardHeight)
    }

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
        VStack(alignment: .leading, spacing: POSSpacing.xSmall) {
            bookingHeaderRow
            bookingDetailsRow
            Spacer().frame(height: POSSpacing.xSmall)
            statusLabels
        }
        .padding(.horizontal, POSPadding.medium * (1 / scale))
        .padding(.vertical, POSPadding.medium * (1 / scale))
        .frame(maxWidth: .infinity, minHeight: dynamicTypeSize.isAccessibilitySize ? nil : minHeight, alignment: .leading)
        .background(Color.posSurfaceContainerLowest)
        .posItemCardBorderStyles()
        .overlay {
            if isSelected {
                RoundedRectangle(cornerRadius: POSCornerRadiusStyle.medium.value)
                    .stroke(Color.posOnSurface, lineWidth: 2)
            }
        }
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var bookingHeaderRow: some View {
        HStack(alignment: .center) {
            Text(booking.customerName)
                .font(.posBodySmallBold())
                .foregroundStyle(Color.posOnSurface)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()

            Text(booking.formattedAmount)
                .font(.posBodySmallRegular())
                .foregroundStyle(Color.posOnSurfaceVariantHighest)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder
    private var bookingDetailsRow: some View {
        VStack(alignment: .leading, spacing: POSSpacing.xSmall) {
            if !booking.serviceName.isEmpty {
                Text(booking.serviceName)
                    .font(.posBodySmallRegular())
                    .foregroundStyle(Color.posOnSurfaceVariantHighest)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Text(formattedTimeRange)
                .font(.posBodySmallRegular())
                .foregroundStyle(Color.posOnSurfaceVariantHighest)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var statusLabels: some View {
        HStack(spacing: POSSpacing.small) {
            if lifecycleStatus.shouldShowBadge {
                Text(lifecycleStatus.localizedTitle)
                    .font(.posBodySmallRegular())
                    .foregroundStyle(lifecycleStatus.badgeColor)
            }

            Text(paymentStatus.localizedTitle)
                .font(.posBodySmallRegular())
                .foregroundStyle(paymentStatus.color)

            Text(attendanceDisplay.localizedTitle)
                .font(.posBodySmallRegular())
                .foregroundStyle(Color.posOnSurfaceVariantHighest)
        }
    }

    private var formattedTimeRange: String {
        let formatter = DateFormatter.timeFormatter
        let start = formatter.string(from: booking.startDate)
        let end = formatter.string(from: booking.endDate)
        return "\(start) – \(end)"
    }
}

private enum Constants {
    static let bookingCardMinHeight: CGFloat = 112
    static let maximumBookingCardHeight: CGFloat = bookingCardMinHeight * 2
}

private extension DateFormatter {
    static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()
}
