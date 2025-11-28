import SwiftUI

/// View for filtering bookings by date and time range
struct BookingDateTimeFilterView: View {
    /// States for the date pickers are required to be non-optional
    @State private var fromDate: Date
    @State private var toDate: Date

    /// Separate states for the selected dates, which can be optional
    @State private var selectedFromDate: Date?
    @State private var selectedToDate: Date?

    @State private var expandedPicker: PickerType?

    enum PickerType: Hashable {
        case fromDate
        case fromTime
        case toDate
        case toTime
    }

    private let onSelection: (Date?, Date?) -> Void

    init(startDate: Date?,
         endDate: Date?,
         onSelection: @escaping (Date?, Date?) -> Void) {
        self.fromDate = startDate ?? Date().startOfDay(timezone: .current)
        self.selectedFromDate = startDate
        self.toDate = endDate ?? Date().endOfDay(timezone: .current)
        self.selectedToDate = endDate
        self.onSelection = onSelection
    }

    var body: some View {
        List {
            // From Section
            Section {
                dateRow(type: .fromDate, displayedDate: $fromDate, selectedDate: selectedFromDate)
                timeRow(type: .fromTime, displayedDate: $fromDate, selectedDate: selectedFromDate)

            } header: {
                Text(Localization.from.uppercased())
                    .footnoteStyle()
            }

            // To Section
            Section {
                dateRow(type: .toDate, displayedDate: $toDate, selectedDate: selectedToDate)
                timeRow(type: .toTime, displayedDate: $toDate, selectedDate: selectedToDate)
            } header: {
                Text(Localization.to.uppercased())
                    .footnoteStyle()
            }
        }
        .listStyle(.plain)
        .navigationTitle(Localization.title)
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.listBackground))
        .onChange(of: fromDate) { _, newValue in
            selectedFromDate = newValue
        }
        .onChange(of: toDate) { _, newValue in
            selectedToDate = newValue
        }
        .onChange(of: selectedFromDate) { _, newValue in
            guard let newValue else {
                return onSelection(nil, selectedToDate)
            }
            /// Bookings backend treats dates as local time with no time zone.
            /// Convert the date to keep the selected components but with UTC as time zone.
            let convertedDate = convertToUTCDate(newValue)
            onSelection(convertedDate, selectedToDate)
        }
        .onChange(of: selectedToDate) { _, newValue in
            guard let newValue else {
                return onSelection(selectedFromDate, nil)
            }
            /// Bookings backend treats dates as local time with no time zone.
            /// Convert the date to keep the selected components but with UTC as time zone.
            let convertedDate = convertToUTCDate(newValue)
            onSelection(selectedFromDate, convertedDate)
        }
    }
}

private extension BookingDateTimeFilterView {
    @ViewBuilder
    func dateRow(type: PickerType, displayedDate: Binding<Date>, selectedDate: Date?) -> some View {
        Button {
            withAnimation {
                expandedPicker = expandedPicker == type ? nil : type
                /// auto selects dates upon expanding the date picker
                if selectedDate == nil {
                    switch type {
                    case .fromDate, .fromTime:
                        selectedFromDate = displayedDate.wrappedValue
                    case .toDate, .toTime:
                        selectedToDate = displayedDate.wrappedValue
                    }
                }
            }
        } label: {
            HStack {
                Text(Localization.date)
                    .foregroundColor(.primary)
                Spacer()
                if let selectedDate {
                    Text(selectedDate, style: .date)
                        .foregroundColor(.secondary)
                }
                Image(systemName: "chevron.forward")
                    .foregroundStyle(Color(.tertiaryLabel))
                    .fontWeight(.medium)
            }
        }

        if expandedPicker == type {
            DatePicker(
                "",
                selection: displayedDate,
                in: dateRange(for: type),
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .labelsHidden()
        }
    }

    @ViewBuilder
    func timeRow(type: PickerType, displayedDate: Binding<Date>, selectedDate: Date?) -> some View {
        Button {
            withAnimation {
                expandedPicker = expandedPicker == type ? nil : type
            }
        } label: {
            HStack {
                Text(Localization.time)
                    .foregroundColor(.primary)
                Spacer()
                if let selectedDate {
                    Text(selectedDate, style: .time)
                        .foregroundColor(.secondary)
                }
                Image(systemName: "chevron.forward")
                    .foregroundStyle(Color(.tertiaryLabel))
                    .fontWeight(.medium)
            }
        }

        if expandedPicker == type {
            DatePicker(
                "",
                selection: displayedDate,
                in: dateRange(for: type),
                displayedComponents: .hourAndMinute
            )
            .datePickerStyle(.wheel)
            .labelsHidden()
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }

    func dateRange(for type: PickerType) -> ClosedRange<Date> {
        switch type {
        case .fromDate, .fromTime:
            return Date.distantPast...toDate
        case .toDate, .toTime:
            return fromDate...Date.distantFuture
        }
    }

    /// Converts a date by extracting its components in the local timezone
    /// and reconstructing a new date with those same components in UTC.
    /// This effectively treats the selected date/time as if it were in UTC.
    func convertToUTCDate(_ date: Date) -> Date {
        let localCalendar = Calendar.current
        let components = localCalendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)

        var utcCalendar = Calendar(identifier: .gregorian)
        utcCalendar.timeZone = TimeZone(identifier: "UTC")!

        return utcCalendar.date(from: components) ?? date
    }
}

private extension BookingDateTimeFilterView {
    enum Localization {
        static let title = NSLocalizedString(
            "bookingDateTimeFilterView.title",
            value: "Date & time",
            comment: "Title of the date time picker for booking filter"
        )
        static let from = NSLocalizedString(
            "bookingDateTimeFilterView.from",
            value: "From",
            comment: "Title of From section in the date time picker for booking filter"
        )
        static let to = NSLocalizedString(
            "bookingDateTimeFilterView.to",
            value: "To",
            comment: "Title of the To section in the date time picker for booking filter"
        )
        static let date = NSLocalizedString(
            "bookingDateTimeFilterView.date",
            value: "Date",
            comment: "Title of the Date row in the date time picker for booking filter"
        )
        static let time = NSLocalizedString(
            "bookingDateTimeFilterView.time",
            value: "Time",
            comment: "Title of the Time row in the date time picker for booking filter"
        )
    }
}

#Preview {
    NavigationView {
        BookingDateTimeFilterView(startDate: nil, endDate: nil, onSelection: { _, _ in })
    }
}
