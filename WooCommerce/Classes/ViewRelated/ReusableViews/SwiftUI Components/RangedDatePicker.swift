import Foundation
import SwiftUI

/// Defines a decoupled way to format selected dates
///
protocol RangedDateTextFormatter {
    func format(start: Date, end: Date) -> String
}

/// View to select a custom date range.
/// Consists of two date pickers laid out vertically.
///
struct RangedDatePicker: View {

    @Environment(\.presentationMode) var presentation

    /// Closure invoked when the custom date range has been confirmed.
    ///
    var datesSelected: ((_ start: Date, _ end: Date) -> Void)?

    /// Start date binding variable
    ///
    @State private var startDate: Date

    /// End date binding variable
    ///
    @State private var endDate: Date

    /// Type to format the subtitle range.
    ///
    private let datesFormatter: RangedDateTextFormatter

    /// Custom `init` to provide intial start and end dates.
    ///
    init(startDate: Date? = nil,
         endDate: Date? = nil,
         datesFormatter: RangedDateTextFormatter,
         datesSelected: ((_ start: Date, _ end: Date) -> Void)? = nil) {
        self._startDate = State(initialValue: startDate ?? Date())
        self._endDate = State(initialValue: endDate ?? Date())
        self.datesFormatter = datesFormatter
        self.datesSelected = datesSelected
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading) {

                    // Start Picker
                    Text(Localization.startDate)
                        .foregroundColor(Color(.accent))
                        .headlineStyle()

                    Divider()

                    DatePicker("", selection: $startDate, in: ...Date(), displayedComponents: [.date])
                        .datePickerStyle(.graphical)
                        .accentColor(Color(.brand))
                        .padding(.horizontal, Layout.calendarPadding)

                    // End Picker
                    Text(Localization.endDate)
                        .foregroundColor(Color(.accent))
                        .headlineStyle()

                    Divider()

                    DatePicker("", selection: $endDate, in: ...Date(), displayedComponents: [.date])
                        .datePickerStyle(.graphical)
                        .accentColor(Color(.brand))
                        .padding(.horizontal, Layout.calendarPadding)
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: {
                ToolbarItem(placement: .principal) {
                    // Navigation Bar title
                    VStack(spacing: Layout.titleSpacing) {
                        Text(Localization.title)
                            .headlineStyle()

                        Text(datesFormatter.format(start: startDate, end: endDate))
                            .captionStyle()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: {
                        presentation.wrappedValue.dismiss()
                        datesSelected?(startDate, endDate)
                    }, label: {
                        Text(Localization.apply)
                    })
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: {
                        presentation.wrappedValue.dismiss()
                    }, label: {
                        Image(uiImage: .closeButton)
                    })
                }
            })
        }
        .navigationViewStyle(.stack)
        .wooNavigationBarStyle()
    }
}

// MARK: Constant

private extension RangedDatePicker {
    enum Localization {
        static let title = NSLocalizedString("Custom Date Range", comment: "Title in custom range date picker")
        static let apply = NSLocalizedString("Apply", comment: "Apply navigation button in custom range date picker")
        static let startDate = NSLocalizedString("Start Date", comment: "Start Date label in custom range date picker")
        static let endDate = NSLocalizedString("End Date", comment: "End Date label in custom range date picker")
    }
    enum Layout {
        static let titleSpacing: CGFloat = 4.0
        static let calendarPadding: CGFloat = -8.0
    }
}

// MARK: Previews

struct RangedDatePickerPreview: PreviewProvider {

    private struct PreviewFormatter: RangedDateTextFormatter {
        func format(start: Date, end: Date) -> String {
            "\(start.description) - \(end.description)"
        }
    }

    static var previews: some View {
        RangedDatePicker(datesFormatter: PreviewFormatter())
    }
}
