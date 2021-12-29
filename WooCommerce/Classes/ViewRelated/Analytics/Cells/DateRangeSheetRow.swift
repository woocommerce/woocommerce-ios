import SwiftUI

// MARK: - DateRangeSheetRow
//
struct DateRangeSheetRow: View {
    let dateRange: String
    @Binding var selectedDateRange: String

    var body: some View {
        VStack(alignment: .leading, spacing: 0, content: {
            HStack(alignment: .center, spacing: 10, content: {
                if dateRange == selectedDateRange {
                    Image(systemName: "checkmark.circle.fill")
                        .resizable()
                        .frame(width: 20, height: 20)
                        .foregroundColor(Color(UIColor.accent))
                } else {
                    Image(systemName: "circle")
                        .resizable()
                        .frame(width: 20, height: 20)
                        .foregroundColor(Color(UIColor.accent))
                }
                Text(dateRange)
                    .foregroundColor(Color(UIColor.text))
            })
            .padding(.vertical, 18)
            Divider()
                .foregroundColor(Color(UIColor.text))
        })
        .padding(.horizontal, 10)
        .background(Color(.listForeground))
        .onTapGesture {
            self.selectedDateRange = self.dateRange
        }
    }
}

struct DateRangeSheetCell_Previews: PreviewProvider {
    static var previews: some View {
        DateRangeSheetRow(dateRange: "Today", selectedDateRange: .constant("Today"))
            .previewLayout(.fixed(width: 375, height: 44))
    }
}
