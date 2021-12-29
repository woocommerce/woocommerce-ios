import SwiftUI

// MARK: - DateRangeSheet
//
struct DateRangeSheet: View {

    // Array with all date range options.
    var dateRanges = DateRanges().objectsArray
    // For closing the sheet.
    @Environment(\.presentationMode) var presentationMode

    @State var tempSelectedDateRange: String = "Yesterday"
    @Binding var selectedDateRange: String

    var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor.listBackground).edgesIgnoringSafeArea(.all)
                VStack(alignment: .leading, spacing: 0, content: {
                    Spacer()
                        .frame(height: 8)
                    ForEach(dateRanges, id: \.self) { item in
                        DateRangeSheetRow(dateRange: item.title, selectedDateRange: $tempSelectedDateRange)
                    }
                    Spacer()
                })
            }
            .toolbar {
                Button(Localization.apply) {
                    // After pressing 'Apply' we confirm that the temporary date range is the date range we want to select.
                    selectedDateRange = tempSelectedDateRange
                    // Close the sheet.
                    presentationMode.wrappedValue.dismiss()
                }
                .foregroundColor(Color(.accent))
            }.onAppear(perform: {
                // Pass the previous selected date range to temporary.
                self.tempSelectedDateRange = selectedDateRange
            })
            .navigationTitle(Localization.title)
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private enum Localization {
        static let title = NSLocalizedString("Select a Date Range", comment: "Title of date range sheet.")
        static let apply = NSLocalizedString("Apply", comment: "Title for the apply button of date range sheet")
    }
}

struct DateRangeSheet_Previews: PreviewProvider {
    static var previews: some View {
        DateRangeSheet(selectedDateRange: .constant("Today"))
    }
}
