import SwiftUI

// MARK: - DateRangeSheet
//
struct DateRangeSheet: View {
    var dateRanges: [String] = [
        Localization.today,
        Localization.yesterday,
        Localization.lastWeek,
        Localization.lastMonth,
        Localization.lastQuarter,
        Localization.lastYear,
        Localization.weekToDate,
        Localization.monthToDate,
        Localization.quarterToDate,
        Localization.yearToDate
    ]

    @Environment(\.presentationMode) var presentationMode

    @Binding var selectedDateRange: String

    var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor.listBackground).edgesIgnoringSafeArea(.all)
                VStack(alignment: .leading, spacing: 0, content: {
                    Spacer()
                        .frame(height: 8)
                    ForEach(dateRanges, id: \.self) { item in
                        DateRangeSheetRow(dateRange: item, selectedDateRange: $selectedDateRange)
                    }
                    Spacer()
                })
            }
            .toolbar {
                Button(Localization.apply) {
                    presentationMode.wrappedValue.dismiss()
                }
                .foregroundColor(Color(.accent))
            }
            .navigationTitle(Localization.title)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct DateRangeSheet_Previews: PreviewProvider {
    static var previews: some View {
        DateRangeSheet(selectedDateRange: .constant("Today"))
    }
}

private extension DateRangeSheet {
    enum Localization {
        static let title = NSLocalizedString("Select Date Range", comment: "Title of date range sheet.")
        static let apply = NSLocalizedString("Apply", comment: "Title for the apply button of date range sheet")
        static let today = NSLocalizedString("Today", comment: "The date range option title that shows the statistics for today.")
        static let yesterday = NSLocalizedString("Yesterday", comment: "The date range option title that shows the statistics for yesterday.")
        static let lastWeek = NSLocalizedString("Last Week", comment: "The date range option title that shows the statistics for last week.")
        static let lastMonth = NSLocalizedString("Last Month", comment: "The date range option title that shows the statistics for last month.")
        static let lastQuarter = NSLocalizedString("Last Quarter", comment: "The date range option title that shows the statistics for last quarter.")
        static let lastYear = NSLocalizedString("Last Year", comment: "The date range option title that shows the statistics for last year.")
        static let weekToDate = NSLocalizedString("Week to date", comment: "The date range option title that shows the statistics for week to date.")
        static let monthToDate = NSLocalizedString("Month to date", comment: "The date range option title that shows the statistics for month to date.")
        static let quarterToDate = NSLocalizedString("Quarter to date", comment: "The date range option title that shows the statistics for quarter to date.")
        static let yearToDate = NSLocalizedString("Year to date", comment: "The date range option title that shows the statistics for year to date.")
    }
}
