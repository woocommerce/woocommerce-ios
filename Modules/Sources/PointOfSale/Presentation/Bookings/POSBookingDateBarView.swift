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
