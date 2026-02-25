import SwiftUI
import struct WooFoundation.WooAnalyticsEvent
import struct Yosemite.POSBooking
import enum Yosemite.BookingAttendanceStatus

struct POSBookingAttendanceSectionView: View {
    let booking: POSBooking

    @Environment(POSBookingsModel.self) private var bookingsModel
    @Environment(\.posAnalytics) private var analytics

    @State private var optimisticAttendanceStatus: BookingAttendanceStatus?
    @State private var attendanceUpdateError = false

    var body: some View {
        VStack(alignment: .leading, spacing: POSSpacing.small) {
            sectionContent
                .sectionCard()

            subtitleText
        }
    }

    private var isUpdatingAttendance: Bool {
        optimisticAttendanceStatus != nil
    }

    private var displayedAttendance: POSBookingAttendanceDisplay {
        POSBookingAttendanceDisplay(attendanceStatus: optimisticAttendanceStatus ?? booking.attendanceStatus)
    }

    @ViewBuilder
    private var sectionContent: some View {
        HStack(alignment: .top) {
            Text(Localization.attendanceStatusTitle)
                .font(.posBodyXLargeRegular)
                .foregroundStyle(Color.posOnSurface)
                .accessibilityAddTraits(.isHeader)
            Spacer()
            HStack(spacing: POSSpacing.small) {
                attendanceButton(Localization.attendedPill,
                                 isSelected: displayedAttendance == .attended) {
                    performAttendanceUpdate(targetStatus: .attended)
                }
                attendanceButton(Localization.unattendedPill,
                                 isSelected: displayedAttendance == .unattended) {
                    performAttendanceUpdate(targetStatus: .unattended)
                }
            }
            .disabled(isUpdatingAttendance)
            .shimmering(active: isUpdatingAttendance)
        }
    }

    @ViewBuilder
    private var subtitleText: some View {
        if attendanceUpdateError {
            Text(Localization.attendanceUpdateErrorMessage)
                .font(.posBodySmallRegular())
                .foregroundStyle(Color.posError)
                .padding(.horizontal, POSPadding.xSmall)
        } else {
            Text(Localization.attendanceSubtitle)
                .font(.posBodySmallRegular())
                .foregroundStyle(Color.posOnSurfaceVariantHighest)
                .padding(.horizontal, POSPadding.xSmall)
        }
    }

    private func performAttendanceUpdate(targetStatus: BookingAttendanceStatus) {
        guard targetStatus != booking.attendanceStatus else { return }
        optimisticAttendanceStatus = targetStatus
        attendanceUpdateError = false
        Task { @MainActor in
            do {
                try await bookingsModel.bookingsController.updateAttendanceStatus(
                    bookingID: booking.id,
                    status: targetStatus
                )
                analytics.track(event: WooAnalyticsEvent.PointOfSale.bookingAttendanceChanged(bookingID: booking.id))
            } catch {
                analytics.track(event: WooAnalyticsEvent.PointOfSale.bookingAttendanceChangeFailed(bookingID: booking.id, error: error))
                attendanceUpdateError = true
            }
            optimisticAttendanceStatus = nil
        }
    }

    @ViewBuilder
    private func attendanceButton(_ title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        if isSelected {
            Button(title, action: action)
                .buttonStyle(POSFilledAttendanceButtonStyle())
                .accessibilityAddTraits(.isSelected)
        } else {
            Button(title, action: action)
                .buttonStyle(POSOutlinedButtonStyle(size: .compact))
                .accessibilityRemoveTraits(.isSelected)
        }
    }
}

// MARK: - Attendance Button Style

private struct POSFilledAttendanceButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) private var colorScheme

    private var fillColor: Color {
        colorScheme == .dark ? .posSecondary : .posPrimaryContainer
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.posBodySmallBold())
            .padding(.vertical, POSPadding.small)
            .padding(.horizontal, POSPadding.medium)
            .foregroundStyle(Color.posOnInverseSurface)
            .background(fillColor)
            .clipShape(RoundedRectangle(cornerRadius: POSCornerRadiusStyle.small.value))
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Localization

private enum Localization {
    static let attendanceStatusTitle = NSLocalizedString(
        "pos.bookingDetailView.attendanceStatusTitle",
        value: "Attendance status",
        comment: "Section title for the attendance status in booking details."
    )

    static let attendedPill = NSLocalizedString(
        "pos.bookingDetailView.attendedPill",
        value: "Attended",
        comment: "Label for the attended pill button in booking attendance section."
    )

    static let unattendedPill = NSLocalizedString(
        "pos.bookingDetailView.unattendedPill",
        value: "Unattended",
        comment: "Label for the unattended pill button in booking attendance section."
    )

    static let attendanceSubtitle = NSLocalizedString(
        "pos.bookingDetailView.attendanceSubtitle",
        value: "Mark attendance to keep your reports accurate and spot booking trends.",
        comment: "Subtitle text below the attendance section explaining why marking attendance matters."
    )

    static let attendanceUpdateErrorMessage = NSLocalizedString(
        "pos.bookingDetailView.attendanceUpdateError",
        value: "Failed to update attendance. Please try again.",
        comment: "Error message shown below attendance section when updating attendance status fails."
    )
}
