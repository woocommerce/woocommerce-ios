import SwiftUI
import struct Yosemite.POSBooking
import enum Yosemite.BookingStatus
import enum Yosemite.BookingPaymentStatus

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
        if booking.bookingStatus == .cancelled {
            Text(booking.bookingStatus.displayName)
                .font(.posBodySmallRegular())
                .foregroundStyle(Color.posError)
        } else {
            Text(booking.paymentStatus.displayName)
                .font(.posBodySmallRegular())
                .foregroundStyle(paymentStatusColor)
        }
    }

    private var formattedTimeRange: String {
        let formatter = DateFormatter.timeFormatter
        let start = formatter.string(from: booking.startDate)
        let end = formatter.string(from: booking.endDate)
        return "\(start) – \(end)"
    }

    private var paymentStatusColor: Color {
        switch booking.paymentStatus {
        case .paid:
            return .posSuccess
        case .unpaid:
            return .posAlert
        case .refunded, .unknown:
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
        case .booked:
            return NSLocalizedString("pos.bookingStatus.booked", value: "Booked", comment: "Booking status: booked")
        case .completed:
            return NSLocalizedString("pos.bookingStatus.completed", value: "Completed", comment: "Booking status: completed")
        case .cancelled:
            return NSLocalizedString("pos.bookingStatus.cancelled", value: "Cancelled", comment: "Booking status: cancelled")
        case .unknown:
            return NSLocalizedString("pos.bookingStatus.unknown", value: "Unknown", comment: "Booking status: unknown")
        }
    }
}

extension BookingPaymentStatus {
    var displayName: String {
        switch self {
        case .paid:
            return NSLocalizedString("pos.paymentStatus.paid", value: "Paid", comment: "Payment status: paid")
        case .unpaid:
            return NSLocalizedString("pos.paymentStatus.unpaid", value: "Unpaid", comment: "Payment status: unpaid")
        case .refunded:
            return NSLocalizedString("pos.paymentStatus.refunded", value: "Refunded", comment: "Payment status: refunded")
        case .unknown:
            return NSLocalizedString("pos.paymentStatus.unknown", value: "Unknown", comment: "Payment status: unknown")
        }
    }
}
