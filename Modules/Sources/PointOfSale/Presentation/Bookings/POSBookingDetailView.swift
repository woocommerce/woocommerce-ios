// POSBookingDetailView.swift
import SwiftUI

struct POSBookingDetailView: View {
    let booking: POSBooking
    let isRefreshing: Bool
    let onBack: () -> Void
    let onPayByCard: () -> Void
    let onPayByCash: () -> Void

    init(booking: POSBooking,
         isRefreshing: Bool = false,
         onBack: @escaping () -> Void,
         onPayByCard: @escaping () -> Void,
         onPayByCash: @escaping () -> Void) {
        self.booking = booking
        self.isRefreshing = isRefreshing
        self.onBack = onBack
        self.onPayByCard = onPayByCard
        self.onPayByCash = onPayByCash
    }

    @Environment(\.siteTimezone) private var siteTimezone
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, dd MMMM yyyy"
        formatter.timeZone = siteTimezone
        return formatter
    }

    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        formatter.timeZone = siteTimezone
        return formatter
    }

    var body: some View {
        VStack(spacing: 0) {
            if horizontalSizeClass == .compact {
                POSPageHeaderView(
                    title: Localization.title,
                    backButtonConfiguration: .init(state: .enabled, action: onBack)
                )
            }

            ScrollView {
                VStack(alignment: .leading, spacing: POSSpacing.large) {
                    bookingInfoSection
                    statusBadgesSection
                    Divider()
                    customerSection
                    Divider()
                    paymentBreakdownSection
                    paymentActionsSection
                }
                .padding(POSSpacing.large)
            }
        }
        .background(Color.posSurface)
    }

    // MARK: - Booking Info Section

    @ViewBuilder
    private var bookingInfoSection: some View {
        VStack(alignment: .leading, spacing: POSSpacing.small) {
            // Service name with optional team member
            HStack(spacing: POSSpacing.xSmall) {
                Text(booking.serviceName)
                    .font(.posBodyXLargeBold)
                    .foregroundStyle(Color.posOnSurface)

                if let resourceName = booking.resourceName {
                    Text("·")
                        .font(.posBodyXLargeBold)
                        .foregroundStyle(Color.posOnSurfaceVariantHighest)
                    Text(resourceName)
                        .font(.posBodyXLargeBold)
                        .foregroundStyle(Color.posOnSurfaceVariantHighest)
                }
            }

            // Date
            Text(dateFormatter.string(from: booking.startTime))
                .font(.posBodyLargeRegular())
                .foregroundStyle(Color.posOnSurfaceVariantHighest)

            // Time range and duration
            HStack(spacing: POSSpacing.xSmall) {
                Text(timeRangeText)
                    .font(.posBodyMediumRegular())
                    .foregroundStyle(Color.posOnSurfaceVariantHighest)

                Text("·")
                    .font(.posBodyMediumRegular())
                    .foregroundStyle(Color.posOnSurfaceVariantHighest)

                Text(durationText)
                    .font(.posBodyMediumRegular())
                    .foregroundStyle(Color.posOnSurfaceVariantHighest)
            }
        }
    }

    private var timeRangeText: String {
        "\(timeFormatter.string(from: booking.startTime)) - \(timeFormatter.string(from: booking.endTime))"
    }

    private var durationText: String {
        let minutes = booking.durationMinutes
        if minutes >= 60 {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            if remainingMinutes > 0 {
                return String(format: Localization.durationHoursMinutes, hours, remainingMinutes)
            }
            return String(format: Localization.durationHours, hours)
        }
        return String(format: Localization.durationMinutes, minutes)
    }

    // MARK: - Status Badges Section

    @ViewBuilder
    private var statusBadgesSection: some View {
        if isRefreshing {
            HStack(spacing: POSSpacing.small) {
                // Placeholder badges
                RoundedRectangle(cornerRadius: POSSpacing.xSmall)
                    .fill(Color.posSurfaceContainerLow)
                    .frame(width: 70, height: 28)
                RoundedRectangle(cornerRadius: POSSpacing.xSmall)
                    .fill(Color.posSurfaceContainerLow)
                    .frame(width: 60, height: 28)
            }
            .shimmering()
        } else {
            HStack(spacing: POSSpacing.small) {
                attendanceStatusBadge
                paymentStatusBadge
            }
        }
    }

    @ViewBuilder
    private var attendanceStatusBadge: some View {
        let config = attendanceStatusConfiguration
        Text(config.text)
            .font(.posBodySmallBold())
            .foregroundStyle(config.foreground)
            .padding(.horizontal, POSSpacing.small)
            .padding(.vertical, POSSpacing.xSmall)
            .background(config.background)
            .clipShape(RoundedRectangle(cornerRadius: POSSpacing.xSmall))
    }

    private var attendanceStatusConfiguration: (text: String, foreground: Color, background: Color) {
        switch booking.attendanceStatus {
        case .booked:
            return (Localization.booked, Color.posOnInfoLowest, Color.posInfoLowest)
        case .checkedIn:
            return (Localization.checkedIn, Color.posOnSuccess, Color.posSuccess)
        case .cancelled:
            return (Localization.cancelled, Color.posOnSurfaceVariantHighest, Color.posSurfaceContainerLow)
        case .noShow:
            return (Localization.noShow, Color.posOnError, Color.posError)
        case .unknown:
            return (Localization.unknown, Color.posOnSurfaceVariantHighest, Color.posSurfaceContainerLow)
        }
    }

    @ViewBuilder
    private var paymentStatusBadge: some View {
        let config = paymentStatusConfiguration
        Text(config.text)
            .font(.posBodySmallBold())
            .foregroundStyle(config.foreground)
            .padding(.horizontal, POSSpacing.small)
            .padding(.vertical, POSSpacing.xSmall)
            .background(config.background)
            .clipShape(RoundedRectangle(cornerRadius: POSSpacing.xSmall))
    }

    private var paymentStatusConfiguration: (text: String, foreground: Color, background: Color) {
        if booking.isPaid {
            return (Localization.paid, Color.posOnSuccess, Color.posSuccess)
        }
        if booking.orderID == nil {
            return (Localization.noOrder, Color.posOnError, Color.posError)
        }
        return (Localization.unpaid, Color.posOnAlert, Color.posAlert)
    }

    // MARK: - Customer Section

    @ViewBuilder
    private var customerSection: some View {
        VStack(alignment: .leading, spacing: POSSpacing.small) {
            Text(Localization.customer)
                .font(.posBodyMediumBold)
                .foregroundStyle(Color.posOnSurfaceVariantHighest)

            Text(booking.customerName)
                .font(.posBodyLargeBold)
                .foregroundStyle(Color.posOnSurface)

            if let email = booking.customerEmail, !email.isEmpty {
                Text(email)
                    .font(.posBodyMediumRegular())
                    .foregroundStyle(Color.posOnSurfaceVariantHighest)
            }

            if let phone = booking.customerPhone, !phone.isEmpty {
                Text(phone)
                    .font(.posBodyMediumRegular())
                    .foregroundStyle(Color.posOnSurfaceVariantHighest)
            }
        }
    }

    // MARK: - Payment Breakdown Section

    @ViewBuilder
    private var paymentBreakdownSection: some View {
        VStack(spacing: POSSpacing.small) {
            if let subtotal = booking.subtotal {
                paymentRow(label: Localization.subtotal, value: subtotal)
            }

            if let tax = booking.tax {
                paymentRow(label: Localization.tax, value: tax)
            }

            paymentRow(label: Localization.total, value: booking.amount, isBold: true)
        }
    }

    @ViewBuilder
    private func paymentRow(label: String, value: String, isBold: Bool = false) -> some View {
        HStack {
            Text(label)
                .font(isBold ? .posBodyLargeBold : .posBodyMediumRegular())
                .foregroundStyle(isBold ? Color.posOnSurface : Color.posOnSurfaceVariantHighest)

            Spacer()

            Text(value)
                .font(isBold ? .posBodyXLargeBold : .posBodyMediumRegular())
                .foregroundStyle(isBold ? Color.posOnSurface : Color.posOnSurfaceVariantHighest)
        }
    }

    // MARK: - Payment Actions Section

    @ViewBuilder
    private var paymentActionsSection: some View {
        if isRefreshing {
            // Placeholder action area while refreshing
            RoundedRectangle(cornerRadius: POSSpacing.small)
                .fill(Color.posSurfaceContainerLow)
                .frame(height: 52)
                .shimmering()
        } else {
            switch booking.status {
            case .unpaid:
                VStack(spacing: POSSpacing.medium) {
                    Button(Localization.payByCard) {
                        onPayByCard()
                    }
                    .buttonStyle(POSFilledButtonStyle(size: .normal))

                    Button(Localization.payByCash) {
                        onPayByCash()
                    }
                    .buttonStyle(POSOutlinedButtonStyle(size: .normal))
                }

            case .paid:
                statusMessage(
                    icon: "checkmark.circle.fill",
                    text: Localization.paymentComplete,
                    color: .posSuccess
                )

            case .cancelled:
                statusMessage(
                    icon: "xmark.circle.fill",
                    text: Localization.bookingCancelled,
                    color: .posOnSurfaceVariantHighest
                )

            case .noLinkedOrder:
                statusMessage(
                    icon: "exclamationmark.triangle.fill",
                    text: Localization.noLinkedOrder,
                    color: .posError
                )
            }
        }
    }

    @ViewBuilder
    private func statusMessage(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: POSSpacing.small) {
            Image(systemName: icon)
                .foregroundStyle(color)
            Text(text)
                .font(.posBodyLargeRegular())
                .foregroundStyle(Color.posOnSurfaceVariantHighest)
        }
        .frame(maxWidth: .infinity)
        .padding(POSSpacing.medium)
        .background(Color.posSurfaceContainerLow)
        .clipShape(RoundedRectangle(cornerRadius: POSSpacing.small))
    }

    // MARK: - Localization

    private enum Localization {
        static let title = NSLocalizedString(
            "posBookingDetail.title",
            value: "Booking",
            comment: "Title for booking detail view"
        )
        static let customer = NSLocalizedString(
            "posBookingDetail.customer",
            value: "Customer",
            comment: "Customer section header"
        )
        static let subtotal = NSLocalizedString(
            "posBookingDetail.subtotal",
            value: "Subtotal",
            comment: "Subtotal label"
        )
        static let tax = NSLocalizedString(
            "posBookingDetail.tax",
            value: "Tax",
            comment: "Tax label"
        )
        static let total = NSLocalizedString(
            "posBookingDetail.total",
            value: "Total",
            comment: "Total label"
        )
        static let payByCard = NSLocalizedString(
            "posBookingDetail.payByCard",
            value: "Pay by Card",
            comment: "Card payment button"
        )
        static let payByCash = NSLocalizedString(
            "posBookingDetail.payByCash",
            value: "Pay by Cash",
            comment: "Cash payment button"
        )
        static let paymentComplete = NSLocalizedString(
            "posBookingDetail.paymentComplete",
            value: "Payment Complete",
            comment: "Status for paid booking"
        )
        static let bookingCancelled = NSLocalizedString(
            "posBookingDetail.bookingCancelled",
            value: "Booking Cancelled",
            comment: "Status for cancelled booking"
        )
        static let noLinkedOrder = NSLocalizedString(
            "posBookingDetail.noLinkedOrder",
            value: "No order linked to this booking",
            comment: "Status for booking without order"
        )

        // Attendance status badges
        static let booked = NSLocalizedString(
            "posBookingDetail.booked",
            value: "Booked",
            comment: "Attendance status badge"
        )
        static let checkedIn = NSLocalizedString(
            "posBookingDetail.checkedIn",
            value: "Checked In",
            comment: "Attendance status badge"
        )
        static let cancelled = NSLocalizedString(
            "posBookingDetail.cancelled",
            value: "Cancelled",
            comment: "Attendance status badge"
        )
        static let noShow = NSLocalizedString(
            "posBookingDetail.noShow",
            value: "No Show",
            comment: "Attendance status badge"
        )
        static let unknown = NSLocalizedString(
            "posBookingDetail.unknown",
            value: "Unknown",
            comment: "Attendance status badge"
        )

        // Payment status badges
        static let paid = NSLocalizedString(
            "posBookingDetail.paid",
            value: "Paid",
            comment: "Payment status badge"
        )
        static let unpaid = NSLocalizedString(
            "posBookingDetail.unpaid",
            value: "Unpaid",
            comment: "Payment status badge"
        )
        static let noOrder = NSLocalizedString(
            "posBookingDetail.noOrder",
            value: "No Order",
            comment: "Payment status badge"
        )

        // Duration formatting
        static let durationMinutes = NSLocalizedString(
            "posBookingDetail.durationMinutes",
            value: "%d min",
            comment: "Duration in minutes. %d is the number of minutes."
        )
        static let durationHours = NSLocalizedString(
            "posBookingDetail.durationHours",
            value: "%d hr",
            comment: "Duration in hours. %d is the number of hours."
        )
        static let durationHoursMinutes = NSLocalizedString(
            "posBookingDetail.durationHoursMinutes",
            value: "%d hr %d min",
            comment: "Duration in hours and minutes. First %d is hours, second is minutes."
        )
    }
}
