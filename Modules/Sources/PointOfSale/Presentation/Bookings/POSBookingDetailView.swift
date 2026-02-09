import SwiftUI
import struct Yosemite.POSBooking
import enum Yosemite.BookingStatus

struct POSBookingDetailView: View {
    let booking: POSBooking
    let onBack: () -> Void

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var shouldShowBackButton: Bool {
        horizontalSizeClass == .compact
    }

    var body: some View {
        VStack(spacing: POSSpacing.none) {
            POSPageHeaderView(
                title: booking.serviceName.isEmpty ? Localization.bookingTitle : booking.serviceName,
                backButtonConfiguration: shouldShowBackButton ? .init(state: .enabled, action: onBack) : nil
            )

            ScrollView {
                VStack(alignment: .leading, spacing: POSSpacing.medium) {
                    detailsCard
                }
                .padding(.top, POSPadding.xSmall)
                .padding(.horizontal, POSPadding.medium)
                .padding(.bottom, POSPadding.medium)
            }
        }
        .background(Color.posSurface)
        .navigationBarHidden(true)
    }

    @ViewBuilder
    private var detailsCard: some View {
        VStack(alignment: .leading, spacing: POSSpacing.medium) {
            detailRow(label: Localization.customerLabel, value: booking.customerName)

            if !booking.serviceName.isEmpty {
                detailRow(label: Localization.serviceLabel, value: booking.serviceName)
            }

            detailRow(label: Localization.dateLabel, value: formattedDate)
            detailRow(label: Localization.timeLabel, value: formattedTimeRange)

            if let resourceName = booking.resourceName {
                detailRow(label: Localization.resourceLabel, value: resourceName)
            }

            Divider()
                .overlay(Color.posOutlineVariant.opacity(0.5))

            detailRow(label: Localization.amountLabel, value: booking.formattedAmount)

            Divider()
                .overlay(Color.posOutlineVariant.opacity(0.5))

            statusRow
        }
        .padding(POSPadding.medium)
        .background(Color.posSurfaceContainerLowest)
        .posItemCardBorderStyles()
    }

    @ViewBuilder
    private func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.posBodySmallRegular())
                .foregroundStyle(Color.posOnSurfaceVariantHighest)

            Spacer()

            Text(value)
                .font(.posBodySmallBold())
                .foregroundStyle(Color.posOnSurface)
        }
    }

    @ViewBuilder
    private var statusRow: some View {
        HStack {
            Text(Localization.statusLabel)
                .font(.posBodySmallRegular())
                .foregroundStyle(Color.posOnSurfaceVariantHighest)

            Spacer()

            Text(booking.status.displayName)
                .font(.posBodySmallBold())
                .foregroundStyle(statusColor)
        }
    }

    private var formattedDate: String {
        DateFormatter.dateOnlyFormatter.string(from: booking.startDate)
    }

    private var formattedTimeRange: String {
        let formatter = DateFormatter.timeOnlyFormatter
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

private extension DateFormatter {
    static let dateOnlyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    static let timeOnlyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()
}

private enum Localization {
    static let bookingTitle = NSLocalizedString(
        "pos.bookingDetailView.bookingTitle",
        value: "Booking",
        comment: "Default title for the booking detail view when no service name is available."
    )

    static let customerLabel = NSLocalizedString(
        "pos.bookingDetailView.customerLabel",
        value: "Customer",
        comment: "Label for the customer name in booking details."
    )

    static let serviceLabel = NSLocalizedString(
        "pos.bookingDetailView.serviceLabel",
        value: "Service",
        comment: "Label for the service name in booking details."
    )

    static let dateLabel = NSLocalizedString(
        "pos.bookingDetailView.dateLabel",
        value: "Date",
        comment: "Label for the date in booking details."
    )

    static let timeLabel = NSLocalizedString(
        "pos.bookingDetailView.timeLabel",
        value: "Time",
        comment: "Label for the time range in booking details."
    )

    static let resourceLabel = NSLocalizedString(
        "pos.bookingDetailView.resourceLabel",
        value: "Resource",
        comment: "Label for the resource name in booking details."
    )

    static let amountLabel = NSLocalizedString(
        "pos.bookingDetailView.amountLabel",
        value: "Amount",
        comment: "Label for the booking amount in booking details."
    )

    static let statusLabel = NSLocalizedString(
        "pos.bookingDetailView.statusLabel",
        value: "Status",
        comment: "Label for the booking status in booking details."
    )
}
