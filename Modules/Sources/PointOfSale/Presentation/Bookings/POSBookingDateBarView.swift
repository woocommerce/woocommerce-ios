import SwiftUI
import struct WooFoundation.WooAnalyticsEvent

struct POSBookingDateBarView: View {
    @Environment(POSBookingsModel.self) private var bookingsModel
    @Environment(\.posAnalytics) private var analytics
    @State private var showingCalendar = false

    private var formattedDate: String {
        POSBookingDateFormatter.formattedShortDate(for: bookingsModel.bookingsController.selectedDate)
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: POSSpacing.small) {
                Button {
                    trackDateNavigation(dayOffset: -1, event: WooAnalyticsEvent.PointOfSale.bookingDatePreviousTapped)
                    Task { await bookingsModel.bookingsController.goToPreviousDay() }
                } label: {
                    Text("\(Image(systemName: "chevron.backward"))")
                }
                .buttonStyle(POSTonalButtonStyle(size: .extraSmall))
                .accessibilityLabel(Localization.previousDay)

                Button {
                    showingCalendar = true
                } label: {
                    Label(formattedDate, systemImage: "calendar")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(POSTonalButtonStyle(size: .extraSmall))
                .accessibilityLabel(String(format: Localization.selectedDateFormat, formattedDate))
                .popover(isPresented: $showingCalendar) {
                    POSBookingCalendarView(
                        selectedDate: bookingsModel.bookingsController.selectedDate,
                        onDateSelected: { date in
                            showingCalendar = false
                            trackDateNavigation(to: date, event: WooAnalyticsEvent.PointOfSale.bookingDateCalendarSelected)
                            Task { await bookingsModel.bookingsController.selectDate(date) }
                        }
                    )
                }

                Button {
                    trackDateNavigation(dayOffset: 1, event: WooAnalyticsEvent.PointOfSale.bookingDateNextTapped)
                    Task { await bookingsModel.bookingsController.goToNextDay() }
                } label: {
                    Text("\(Image(systemName: "chevron.forward"))")
                }
                .buttonStyle(POSTonalButtonStyle(size: .extraSmall))
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

private extension POSBookingDateBarView {
    /// Tracks a date navigation event for a relative day offset (e.g. -1 for previous, +1 for next).
    func trackDateNavigation(dayOffset: Int, event: (Int) -> WooAnalyticsEvent) {
        let targetDate = POSBookingDateFormatter.utcCalendar.date(
            byAdding: .day, value: dayOffset, to: bookingsModel.bookingsController.selectedDate
        ) ?? bookingsModel.bookingsController.selectedDate
        analytics.track(event: event(deltaFromToday(for: targetDate)))
    }

    /// Tracks a date navigation event for an absolute target date (e.g. calendar selection).
    func trackDateNavigation(to date: Date, event: (Int) -> WooAnalyticsEvent) {
        analytics.track(event: event(deltaFromToday(for: date)))
    }

    func deltaFromToday(for date: Date) -> Int {
        let today = POSBookingDateFormatter.utcCalendar.startOfDay(for: Date())
        let target = POSBookingDateFormatter.utcCalendar.startOfDay(for: date)
        return POSBookingDateFormatter.utcCalendar.dateComponents([.day], from: today, to: target).day ?? 0
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
