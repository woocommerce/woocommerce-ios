import SwiftUI

struct POSBookingDateBarView: View {
    @Environment(POSBookingsModel.self) private var bookingsModel
    @Environment(\.siteTimezone) private var siteTimezone
    @Environment(\.colorScheme) private var colorScheme
    @ScaledMetric private var chevronSize: CGFloat = Constants.chevronSize
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
        HStack(spacing: POSSpacing.medium) {
            Button {
                Task { await bookingsModel.bookingsController.goToPreviousDay() }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: chevronSize, weight: .medium))
                    .foregroundStyle(tintColor)
            }
            .buttonStyle(.plain)

            Button {
                showingCalendar = true
            } label: {
                HStack(spacing: POSSpacing.small) {
                    Image(systemName: "calendar")
                        .foregroundStyle(tintColor)

                    Text(formattedDate)
                        .font(.posBodyMediumRegular())
                        .foregroundStyle(tintColor)
                }
            }
            .buttonStyle(.plain)
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
                    .font(.system(size: chevronSize, weight: .medium))
                    .foregroundStyle(tintColor)
            }
            .buttonStyle(.plain)

            Spacer()
        }
        .padding(.horizontal, POSPadding.large)
        .padding(.bottom, POSPadding.large)
    }
}

private enum Constants {
    static let chevronSize: CGFloat = 12
}
