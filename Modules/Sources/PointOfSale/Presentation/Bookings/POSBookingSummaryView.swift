import SwiftUI
import struct Yosemite.POSBooking

struct POSBookingSummaryView: View {
    let booking: POSBooking

    private var lifecycleStatus: POSBookingLifecycleStatus {
        POSBookingLifecycleStatus(bookingStatus: booking.status)
    }

    private var paymentStatus: POSBookingPaymentStatus {
        POSBookingPaymentStatus(bookingStatus: booking.status, orderStatus: booking.order.status)
    }

    private var attendanceDisplay: POSBookingAttendanceDisplay {
        POSBookingAttendanceDisplay(attendanceStatus: booking.attendanceStatus)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: POSSpacing.small) {
            subtitleText
            statusBadges
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    @ViewBuilder
    private var subtitleText: some View {
        let text = formattedSubtitle
        if !text.isEmpty {
            Text(text)
                .font(.posBodyMediumRegular())
                .foregroundStyle(Color.posOnSurfaceVariantHighest)
                .fixedSize(horizontal: false, vertical: true)
        }
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

    private var formattedSubtitle: String {
        let customerDisplayName = booking.customerName ?? booking.customerEmail
        let parts = [booking.serviceName, customerDisplayName].compactMap { $0 }.filter { !$0.isEmpty }
        return parts.joined(separator: " \u{00B7} ")
    }

    private var accessibilityLabel: String {
        let parts = [
            booking.serviceName,
            booking.customerName ?? booking.customerEmail,
            lifecycleStatus == .cancelled ? lifecycleStatus.localizedTitle : attendanceDisplay.localizedTitle,
            paymentStatus.localizedTitle
        ].compactMap { $0 }.filter { !$0.isEmpty }
        return parts.joined(separator: ", ")
    }
}

// MARK: - Date Formatting

extension POSBookingSummaryView {
    static func formattedTimeRange(for booking: POSBooking) -> String {
        let dateString = DateFormatter.posShortDateFormatter.string(from: booking.startDate)
        let startTime = DateFormatter.posTimeFormatter.string(from: booking.startDate)
        let endTime = DateFormatter.posTimeFormatter.string(from: booking.endDate)
        return "\(dateString), \(startTime)-\(endTime)"
    }
}

private extension DateFormatter {
    static let posTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()

    static let posShortDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("MM/dd/yyyy")
        return formatter
    }()
}
