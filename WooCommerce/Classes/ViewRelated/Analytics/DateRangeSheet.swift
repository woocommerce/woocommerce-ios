import SwiftUI

// MARK: - DateRangeSheet
//
struct DateRangeSheet: View {

    // Array with all date range options
    var dateRanges = DateRanges().objectsArray

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
                        DateRangeSheetRow(dateRange: item.title, selectedDateRange: $selectedDateRange)
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
        static let title = NSLocalizedString("Select a Date Range", comment: "Title of date range sheet.")
        static let apply = NSLocalizedString("Apply", comment: "Title for the apply button of date range sheet")
    }
}
