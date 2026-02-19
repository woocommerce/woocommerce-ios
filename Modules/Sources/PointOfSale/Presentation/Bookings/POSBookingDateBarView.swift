import SwiftUI

struct POSBookingDateBarView: View {
    @Environment(POSBookingsModel.self) private var bookingsModel
    @Environment(\.siteTimezone) private var siteTimezone
    @Environment(\.colorScheme) private var colorScheme
    @State private var showingCalendar = false

    private var tintColor: Color {
        colorScheme == .dark ? .posSecondary : .posPrimaryContainer
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("dMMMEEE")
        formatter.timeZone = siteTimezone
        return formatter.string(from: bookingsModel.bookingsController.selectedDate)
    }

    var body: some View {
        VStack(spacing: 0) {
            Divider()
                .overlay(Color.posOutlineVariant)

            HStack(spacing: POSSpacing.medium) {
                Button {
                    Task { await bookingsModel.bookingsController.goToPreviousDay() }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.posButtonSymbolSmall)
                        .foregroundStyle(tintColor)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Localization.previousDay)

                Button {
                    showingCalendar = true
                } label: {
                    HStack(spacing: POSSpacing.small) {
                        Image(systemName: "calendar")
                            .foregroundStyle(tintColor)

                        Text(formattedDate)
                            .font(.posBodySmallRegular())
                            .foregroundStyle(tintColor)
                            .frame(minWidth: Constants.dateTextMinWidth, alignment: .leading)
                    }
                }
                .buttonStyle(.plain)
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
                    Image(systemName: "chevron.right")
                        .font(.posButtonSymbolSmall)
                        .foregroundStyle(tintColor)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Localization.nextDay)

                Spacer()
            }
            .dynamicTypeSize(...DynamicTypeSize.accessibility1)
            .padding(.horizontal, POSPadding.large)
            .frame(height: Constants.barHeight)

            Divider()
                .overlay(Color.posOutlineVariant)
        }
    }
}

private enum Constants {
    static let barHeight: CGFloat = 62
    static let dateTextMinWidth: CGFloat = 140
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
        value: "%@, tap to open calendar",
        comment: "Accessibility label for the date button in the bookings date bar. %@ is the formatted date."
    )
}
