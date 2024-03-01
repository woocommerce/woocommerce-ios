import Foundation
import SwiftUI

/// Defines a decoupled way to format selected dates
///
protocol RangedDateTextFormatter {
    func format(start: Date, end: Date) -> String
}

/// Hosting controller for `RangedDatePicker`
///
final class RangedDatePickerHostingController: UIHostingController<RangedDatePicker> {
    init(startDate: Date? = nil,
         endDate: Date? = nil,
         datesFormatter: RangedDateTextFormatter,
         customApplyButtonTitle: String? = nil,
         datesSelected: ((_ start: Date, _ end: Date) -> Void)? = nil) {
        super.init(rootView: RangedDatePicker(startDate: startDate,
                                              endDate: endDate,
                                              datesFormatter: datesFormatter,
                                              customApplyButtonTitle: customApplyButtonTitle,
                                              datesSelected: datesSelected))
    }

    @available(*, unavailable)
    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
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

    /// Whether to display the alert for invalid date range
    ///
    @State private var shouldShowInvalidDateRangeAlert = false

    /// Type to format the subtitle range.
    ///
    private let datesFormatter: RangedDateTextFormatter

    /// Custom text for the confirm button
    ///
    private let applyButtonTitle: String

    /// Custom `init` to provide intial start and end dates.
    ///
    init(startDate: Date? = nil,
         endDate: Date? = nil,
         datesFormatter: RangedDateTextFormatter,
         customApplyButtonTitle: String? = nil,
         datesSelected: ((_ start: Date, _ end: Date) -> Void)? = nil) {
        self._startDate = State(initialValue: startDate ?? Date())
        self._endDate = State(initialValue: endDate ?? Date())
        self.datesFormatter = datesFormatter
        self.datesSelected = datesSelected
        self.applyButtonTitle = customApplyButtonTitle ?? Localization.apply
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
                        .tint(Color(.brand))
                        .padding(.horizontal, Layout.calendarPadding)

                    // End Picker
                    Text(Localization.endDate)
                        .foregroundColor(Color(.accent))
                        .headlineStyle()

                    Divider()

                    DatePicker("", selection: $endDate, in: ...Date(), displayedComponents: [.date])
                        .datePickerStyle(.graphical)
                        .tint(Color(.brand))
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
                        guard startDate < endDate else {
                            shouldShowInvalidDateRangeAlert = true
                            return
                        }
                        presentation.wrappedValue.dismiss()
                        datesSelected?(startDate, endDate)
                    }, label: {
                        Text(applyButtonTitle)
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
        .alert(Localization.InvalidTimeRangeAlert.title, isPresented: $shouldShowInvalidDateRangeAlert) {
            Button(Localization.InvalidTimeRangeAlert.action) {
                shouldShowInvalidDateRangeAlert = false
            }
        } message: {
            Text(Localization.InvalidTimeRangeAlert.message)
        }

    }
}

// MARK: Constant

private extension RangedDatePicker {
    enum Localization {
        static let title = NSLocalizedString("Custom Date Range", comment: "Title in custom range date picker")
        static let apply = NSLocalizedString("Apply", comment: "Apply navigation button in custom range date picker")
        static let startDate = NSLocalizedString("Start Date", comment: "Start Date label in custom range date picker")
        static let endDate = NSLocalizedString("End Date", comment: "End Date label in custom range date picker")

        enum InvalidTimeRangeAlert {
            static let title = NSLocalizedString(
                "rangedDatePicker.invalidTimeRangeAlert.title",
                value: "Invalid time range",
                comment: "Title of the alert displayed when selecting an invalid time range for analytics"
            )
            static let message = NSLocalizedString(
                "rangedDatePicker.invalidTimeRangeAlert.message",
                value: "The start date should be earlier than the end date. Please select a different time range.",
                comment: "Message of the alert displayed when selecting an invalid time range for analytics"
            )
            static let action = NSLocalizedString(
                "rangedDatePicker.invalidTimeRangeAlert.action",
                value: "Got It",
                comment: "Button to dismiss the alert displayed when selecting an invalid time range for analytics"
            )
        }
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
