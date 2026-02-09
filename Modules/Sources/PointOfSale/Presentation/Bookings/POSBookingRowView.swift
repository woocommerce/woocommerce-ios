import SwiftUI
import struct Yosemite.POSBooking
import enum Yosemite.BookingStatus

struct POSBookingRowView: View {
    let booking: POSBooking
    let isSelected: Bool

    @ScaledMetric private var scale: CGFloat = 1.0
    @Environment(\.dynamicTypeSize) var dynamicTypeSize

    private var minHeight: CGFloat {
        min(Constants.bookingCardMinHeight * scale, Constants.maximumBookingCardHeight)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: POSSpacing.xSmall) {
            bookingHeaderRow
            bookingDetailsRow
            Spacer().frame(height: POSSpacing.xSmall)
            statusText
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
    private var statusText: some View {
        Text(booking.status.displayName)
            .font(.posBodySmallRegular())
            .foregroundStyle(statusColor)
    }

    private var formattedTimeRange: String {
        let formatter = DateFormatter.timeFormatter
        let start = formatter.string(from: booking.startDate)
        let end = formatter.string(from: booking.endDate)
        return "\(start) – \(end)"
    }

    private var statusColor: Color {
        switch booking.status {
        case .confirmed, .paid, .complete:
            return .posSuccess
        case .cancelled:
            return .posError
        case .unpaid, .pendingConfirmation:
            return .posAlert
        case .unknown:
            return .posOnSurfaceVariantHighest
        }
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

extension BookingStatus {
    var displayName: String {
        switch self {
        case .complete:
            return NSLocalizedString("pos.bookingStatus.complete", value: "Complete", comment: "Booking status: complete")
        case .paid:
            return NSLocalizedString("pos.bookingStatus.paid", value: "Paid", comment: "Booking status: paid")
        case .unpaid:
            return NSLocalizedString("pos.bookingStatus.unpaid", value: "Unpaid", comment: "Booking status: unpaid")
        case .cancelled:
            return NSLocalizedString("pos.bookingStatus.cancelled", value: "Cancelled", comment: "Booking status: cancelled")
        case .pendingConfirmation:
            return NSLocalizedString("pos.bookingStatus.pendingConfirmation", value: "Pending", comment: "Booking status: pending confirmation")
        case .confirmed:
            return NSLocalizedString("pos.bookingStatus.confirmed", value: "Confirmed", comment: "Booking status: confirmed")
        case .unknown:
            return NSLocalizedString("pos.bookingStatus.unknown", value: "Unknown", comment: "Booking status: unknown")
        }
    }
}
