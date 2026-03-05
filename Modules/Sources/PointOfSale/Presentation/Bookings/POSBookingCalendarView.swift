import SwiftUI

struct POSBookingCalendarView: View {
    let selectedDate: Date
    let onDateSelected: (Date) -> Void

    @State private var pickerDate: Date

    init(selectedDate: Date, onDateSelected: @escaping (Date) -> Void) {
        self.selectedDate = selectedDate
        self.onDateSelected = onDateSelected
        self._pickerDate = State(initialValue: selectedDate)
    }

    var body: some View {
        DatePicker(
            "",
            selection: $pickerDate,
            displayedComponents: .date
        )
        .datePickerStyle(.graphical)
        .tint(.posPrimaryContainer)
        .environment(\.timeZone, POSBookingDateFormatter.utcTimeZone)
        .onChange(of: pickerDate) { _, newDate in
            onDateSelected(newDate)
        }
        .padding()
        .frame(width: Constants.popoverWidth)
    }
}

private enum Constants {
    static let popoverWidth: CGFloat = 350
}
