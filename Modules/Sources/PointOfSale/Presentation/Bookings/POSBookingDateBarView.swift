import SwiftUI

struct POSBookingDateBarView: View {
    @Environment(POSBookingsModel.self) private var bookingsModel
    @Environment(\.siteTimezone) private var siteTimezone
    @State private var showingCalendar = false

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("dMMMEEE")
        formatter.timeZone = siteTimezone
        return formatter.string(from: bookingsModel.bookingsController.selectedDate)
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: POSSpacing.small) {
                Button {
                    Task { await bookingsModel.bookingsController.goToPreviousDay() }
                } label: {
                    Text("\(Image(systemName: "chevron.backward"))")
                }
                .buttonStyle(POSSurfaceButtonStyle(size: .extraSmall))
                .accessibilityLabel(Localization.previousDay)

                Button {
                    showingCalendar = true
                } label: {
                    Label(formattedDate, systemImage: "calendar")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(POSSurfaceButtonStyle(size: .extraSmall))
                .accessibilityLabel(String(format: Localization.selectedDateFormat, formattedDate))
                .popover(isPresented: $showingCalendar) {
                    POSBookingCalendarView(
                        selectedDate: bookingsModel.bookingsController.selectedDate,
                        siteTimezone: siteTimezone,
                        onDateSelected: { date in
                            showingCalendar = false
                            Task { await bookingsModel.bookingsController.selectDate(date) }
                        }
                    )
                }

                Button {
                    Task { await bookingsModel.bookingsController.goToNextDay() }
                } label: {
                    Text("\(Image(systemName: "chevron.forward"))")
                }
                .buttonStyle(POSSurfaceButtonStyle(size: .extraSmall))
                .accessibilityLabel(Localization.nextDay)
            }
            .font(.posBodySmallBold())
            .dynamicTypeSize(...DynamicTypeSize.accessibility1)
            .padding(.horizontal, POSPadding.medium)
            .padding(.bottom, POSPadding.medium)

            Divider()
                .overlay(Color.posOutlineVariant)
        }
    }
}

private enum Localization {
    static let previousDay = NSLocalizedString(
        "pos.bookingDateBar.previousDay",
        value: "Previous day",
        comment: "Accessibility label for the previous day button in the bookings date bar."
    )

    static let nextDay = NSLocalizedString(
        "pos.bookingDateBar.nextDay",
        value: "Next day",
        comment: "Accessibility label for the next day button in the bookings date bar."
    )

    static let selectedDateFormat = NSLocalizedString(
        "pos.bookingDateBar.selectedDate",
        value: "%1$@, tap to open calendar",
        comment: "Accessibility label for the date button in the bookings date bar. %1$@ is the formatted date."
    )
}
