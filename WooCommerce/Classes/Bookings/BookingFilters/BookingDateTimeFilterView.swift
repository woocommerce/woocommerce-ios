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
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(Localization.clear) {
                    clearDateRange()
                }
                .renderedIf(selectedFromDate != nil || selectedToDate != nil)
            }
        }
        .background(Color(.listBackground))
        .environment(\.timeZone, TimeZone(identifier: "UTC")!) // API treats dates as no timezone so use UTC to display and select dates
        .onChange(of: fromDate) { _, newValue in
            selectedFromDate = newValue
        }
        .onChange(of: toDate) { _, newValue in
            selectedToDate = newValue
        }
        .onChange(of: selectedFromDate) { _, newValue in
            onSelection(newValue, selectedToDate)
        }
        .onChange(of: selectedToDate) { _, newValue in
            onSelection(selectedFromDate, newValue)
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

    func clearDateRange() {
        selectedFromDate = nil
        selectedToDate = nil
        expandedPicker = nil
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
        static let clear = NSLocalizedString(
            "bookingDateTimeFilterView.clear",
            value: "Clear",
            comment: "Title of the Clear button in the date time picker for booking filter"
        )
    }
}

#Preview {
    NavigationView {
        BookingDateTimeFilterView(startDate: nil, endDate: nil, onSelection: { _, _ in })
    }
}
