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
                    let targetDate = POSBookingDateFormatter.utcCalendar.date(
                        byAdding: .day, value: -1, to: bookingsModel.bookingsController.selectedDate
                    )
                    analytics.track(event: WooAnalyticsEvent.PointOfSale.bookingDatePreviousTapped(
                        deltaFromToday: deltaFromToday(for: targetDate ?? bookingsModel.bookingsController.selectedDate)
                    ))
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
                            analytics.track(event: WooAnalyticsEvent.PointOfSale.bookingDateCalendarSelected(
                                deltaFromToday: deltaFromToday(for: date)
                            ))
                            Task { await bookingsModel.bookingsController.selectDate(date) }
                        }
                    )
                }

                Button {
                    let targetDate = POSBookingDateFormatter.utcCalendar.date(
                        byAdding: .day, value: 1, to: bookingsModel.bookingsController.selectedDate
                    )
                    analytics.track(event: WooAnalyticsEvent.PointOfSale.bookingDateNextTapped(
                        deltaFromToday: deltaFromToday(for: targetDate ?? bookingsModel.bookingsController.selectedDate)
                    ))
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
