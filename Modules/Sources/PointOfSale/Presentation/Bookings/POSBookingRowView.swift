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
        .accessibilityHint(Localization.bookingRowAccessibilityHint)
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

                POSBookingBadgeView(title: paymentStatus.localizedTitle,
                                    textColor: paymentStatus.textColor,
                                    backgroundColor: paymentStatus.backgroundColor)
            } else {
                POSBookingBadgeView(title: attendanceDisplay.localizedTitle,
                                    textColor: attendanceDisplay.textColor,
                                    backgroundColor: attendanceDisplay.backgroundColor)

                POSBookingBadgeView(title: paymentStatus.localizedTitle,
                                    textColor: paymentStatus.textColor,
                                    backgroundColor: paymentStatus.backgroundColor)
            }
        }
    }

    private var accessibilityLabel: String {
        var parts = [formattedTimeRange]

        if !booking.serviceName.isEmpty {
            parts.append(Localization.serviceAccessibilityLabel(booking.serviceName))
        }

        if let customerName = booking.customerName {
            parts.append(Localization.customerAccessibilityLabel(customerName))
        } else if let email = booking.customerEmail {
            parts.append(Localization.customerAccessibilityLabel(email))
        }

        if lifecycleStatus == .cancelled {
            parts.append(Localization.bookingStatusAccessibilityLabel(lifecycleStatus.localizedTitle))
        } else {
            parts.append(Localization.attendanceAccessibilityLabel(attendanceDisplay.localizedTitle))
        }

        parts.append(Localization.paymentAccessibilityLabel(paymentStatus.localizedTitle))

        return parts.joined(separator: ", ")
    }

    private var formattedTimeRange: String {
        let formatter = DateFormatter.timeFormatter
        let start = formatter.string(from: booking.startDate)
        let end = formatter.string(from: booking.endDate)
        return "\(start)-\(end)"
    }

    private var detailsText: String {
        let customerDisplayName = booking.customerName ?? booking.customerEmail
        let parts = [booking.serviceName, customerDisplayName].compactMap { $0 }.filter { !$0.isEmpty }
        return parts.joined(separator: " \u{00B7} ")
    }
}

private enum Localization {
    static let bookingRowAccessibilityHint = NSLocalizedString(
        "pos.bookingListView.bookingRow.accessibilityHint",
        value: "Tap to view booking details",
        comment: "Accessibility hint for booking row indicating the action when tapped."
    )

    static func serviceAccessibilityLabel(_ service: String) -> String {
        let format = NSLocalizedString(
            "pos.bookingListView.bookingRow.accessibilityLabel.service",
            value: "Service: %1$@",
            comment: "Service portion of booking row accessibility label. %1$@ is the service name."
        )
        return String(format: format, service)
    }

    static func customerAccessibilityLabel(_ customer: String) -> String {
        let format = NSLocalizedString(
            "pos.bookingListView.bookingRow.accessibilityLabel.customer",
            value: "Customer: %1$@",
            comment: "Customer portion of booking row accessibility label. %1$@ is the customer name or email."
        )
        return String(format: format, customer)
    }

    static func attendanceAccessibilityLabel(_ status: String) -> String {
        let format = NSLocalizedString(
            "pos.bookingListView.bookingRow.accessibilityLabel.attendance",
            value: "Attendance: %1$@",
            comment: "Attendance portion of booking row accessibility label. %1$@ is the attendance status."
        )
        return String(format: format, status)
    }

    static func paymentAccessibilityLabel(_ status: String) -> String {
        let format = NSLocalizedString(
            "pos.bookingListView.bookingRow.accessibilityLabel.payment",
            value: "Payment: %1$@",
            comment: "Payment portion of booking row accessibility label. %1$@ is the payment status."
        )
        return String(format: format, status)
    }

    static func bookingStatusAccessibilityLabel(_ status: String) -> String {
        let format = NSLocalizedString(
            "pos.bookingListView.bookingRow.accessibilityLabel.bookingStatus",
            value: "Status: %1$@",
            comment: "Status portion of booking row accessibility label. %1$@ is the booking lifecycle status (e.g. Cancelled)."
        )
        return String(format: format, status)
    }
}

private extension DateFormatter {
    static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()
}
