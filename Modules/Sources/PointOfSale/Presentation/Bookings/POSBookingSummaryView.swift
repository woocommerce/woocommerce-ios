import SwiftUI
import struct Yosemite.POSBooking

struct POSBookingSummaryView: View {
    let booking: POSBooking

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
            if booking.lifecycleStatus == .cancelled {
                POSBookingBadgeView(title: booking.lifecycleStatus.localizedTitle,
                                    textColor: booking.lifecycleStatus.textColor,
                                    backgroundColor: booking.lifecycleStatus.backgroundColor)
            } else {
                POSBookingBadgeView(title: booking.attendanceDisplay.localizedTitle,
                                    textColor: booking.attendanceDisplay.textColor,
                                    backgroundColor: booking.attendanceDisplay.backgroundColor)
            }
            POSBookingBadgeView(title: booking.paymentStatus.localizedTitle,
                                textColor: booking.paymentStatus.textColor,
                                backgroundColor: booking.paymentStatus.backgroundColor)
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
            booking.lifecycleStatus == .cancelled ? booking.lifecycleStatus.localizedTitle : booking.attendanceDisplay.localizedTitle,
            booking.paymentStatus.localizedTitle
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
