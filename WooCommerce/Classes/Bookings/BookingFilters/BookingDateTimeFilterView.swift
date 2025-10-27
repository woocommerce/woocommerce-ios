import SwiftUI

/// View for filtering bookings by date and time range
struct BookingDateTimeFilterView: View {
    @State private var fromDate: Date
    @State private var toDate: Date

    @State private var expandedPicker: PickerType?

    enum PickerType: Hashable {
        case fromDate
        case fromTime
        case toDate
        case toTime
    }

    private let onSelection: (Date, Date) -> Void

    init(startDate: Date?,
         endDate: Date?,
         onSelection: @escaping (Date, Date) -> Void) {
        self.fromDate = startDate ?? Date()
        self.toDate = endDate ?? Date()
        self.onSelection = onSelection
    }

    var body: some View {
        List {
            // From Section
            Section {
                dateRow(type: .fromDate, selection: $fromDate)
                timeRow(type: .fromTime, selection: $fromDate)

            } header: {
                Text(Localization.from.uppercased())
                    .footnoteStyle()
            }

            // To Section
            Section {
                dateRow(type: .toDate, selection: $toDate)
                timeRow(type: .toTime, selection: $toDate)
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
            onSelection(newValue, toDate)
        }
        .onChange(of: toDate) { _, newValue in
            onSelection(fromDate, newValue)
        }
    }
}

private extension BookingDateTimeFilterView {
    @ViewBuilder
    func dateRow(type: PickerType, selection: Binding<Date>) -> some View {
        Button {
            withAnimation {
                expandedPicker = expandedPicker == type ? nil : type
            }
        } label: {
            HStack {
                Text(Localization.date)
                    .foregroundColor(.primary)
                Spacer()
                Text(selection.wrappedValue, style: .date)
                    .foregroundColor(.secondary)
            }
        }

        if expandedPicker == type {
            DatePicker(
                "",
                selection: selection,
                in: dateRange(for: type),
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .labelsHidden()
        }
    }

    @ViewBuilder
    func timeRow(type: PickerType, selection: Binding<Date>) -> some View {
        Button {
            withAnimation {
                expandedPicker = expandedPicker == type ? nil : type
            }
        } label: {
            HStack {
                Text(Localization.time)
                    .foregroundColor(.primary)
                Spacer()
                Text(selection.wrappedValue, style: .time)
                    .foregroundColor(.secondary)
            }
        }

        if expandedPicker == type {
            DatePicker(
                "",
                selection: selection,
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
            "bookingDateTimeFilterView.title",
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
