// POSBookingRowView.swift
import SwiftUI

struct POSBookingRowView: View {
    let booking: POSBooking
    let isSelected: Bool
    let timeFormatter: DateFormatter

    init(booking: POSBooking, isSelected: Bool, siteTimezone: TimeZone = .current) {
        self.booking = booking
        self.isSelected = isSelected

        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        formatter.timeZone = siteTimezone
        self.timeFormatter = formatter
    }

    var body: some View {
        VStack(alignment: .leading, spacing: POSSpacing.xSmall) {
            HStack {
                Text(booking.customerName)
                    .font(.posBodyLargeBold)
                    .foregroundStyle(Color.posOnSurface)

                Spacer()

                Text(booking.amount)
                    .font(.posBodyLargeBold)
                    .foregroundStyle(Color.posOnSurface)
            }

            HStack(spacing: POSSpacing.small) {
                statusBadge

                Text("·")
                    .foregroundStyle(Color.posOnSurfaceVariantHighest)

                Text(booking.serviceName)
                    .font(.posBodyMediumRegular())
                    .foregroundStyle(Color.posOnSurfaceVariantHighest)

                Text("·")
                    .foregroundStyle(Color.posOnSurfaceVariantHighest)

                Text(timeFormatter.string(from: booking.startTime))
                    .font(.posBodyMediumRegular())
                    .foregroundStyle(Color.posOnSurfaceVariantHighest)
            }
        }
        .padding(POSSpacing.medium)
        .background(Color.posSurfaceContainerLowest)
        .clipShape(RoundedRectangle(cornerRadius: POSSpacing.small))
        .overlay(
            RoundedRectangle(cornerRadius: POSSpacing.small)
                .stroke(isSelected ? Color.posOnSurface : Color.clear, lineWidth: 2)
        )
    }

    @ViewBuilder
    private var statusBadge: some View {
        let config = statusConfiguration
        Text(config.text)
            .font(.posBodySmallBold())
            .foregroundStyle(config.foreground)
            .padding(.horizontal, POSSpacing.small)
            .padding(.vertical, POSSpacing.xSmall)
            .background(config.background)
            .clipShape(RoundedRectangle(cornerRadius: POSSpacing.xSmall))
    }

    private var statusConfiguration: (text: String, foreground: Color, background: Color) {
        switch booking.status {
        case .unpaid:
            return (Localization.unpaid, Color.posOnAlert, Color.posAlert)
        case .paid:
            return (Localization.paid, Color.posOnSuccess, Color.posSuccess)
        case .cancelled:
            return (Localization.cancelled, Color.posOnSurfaceVariantHighest, Color.posSurfaceContainerLow)
        case .noLinkedOrder:
            return (Localization.noOrder, Color.posOnError, Color.posError)
        }
    }

    private enum Localization {
        static let unpaid = NSLocalizedString("posBookingRow.unpaid", value: "Unpaid", comment: "Booking status badge")
        static let paid = NSLocalizedString("posBookingRow.paid", value: "Paid", comment: "Booking status badge")
        static let cancelled = NSLocalizedString("posBookingRow.cancelled", value: "Cancelled", comment: "Booking status badge")
        static let noOrder = NSLocalizedString("posBookingRow.noOrder", value: "No order", comment: "Booking status badge")
    }
}
