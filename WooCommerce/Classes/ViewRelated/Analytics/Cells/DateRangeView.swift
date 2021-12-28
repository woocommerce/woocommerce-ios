import SwiftUI

// MARK: - DateRangeView

//
struct DateRangeView: View {
    @State var selectedRange: String
    @State private var showingSheet = false

    var body: some View {
        VStack {
            Divider()
            Button {
                showingSheet.toggle()
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 12, content: {
                        Text("Today (Sep 10, 2020)")
                            .font(.system(size: 17))
                            .foregroundColor(Color(UIColor.text))
                        Text("vs Previous Period (Sep 9, 2020)")
                            .font(.system(size: 13))
                            .foregroundColor(Color(UIColor.text))
                    })
                    Spacer()
                    Image(systemName: "calendar")
                        .renderingMode(.template)
                        .foregroundColor(Color(UIColor.accent))
                }
                .padding(EdgeInsets(top: Constants.buttonContentTop,
                                    leading: Constants.buttonContentLeading,
                                    bottom: Constants.buttonContentBottom,
                                    trailing: Constants.buttonContentTrailing))
            }
            .sheet(isPresented: $showingSheet) {
                DateRangeSheet(selectedDateRange: $selectedRange)
            }
            Divider()
        }
        .background(Color(.listForeground))
    }
}

struct DateRangeView_Previews: PreviewProvider {
    static var previews: some View {
        DateRangeView(selectedRange: "Today").previewLayout(.fixed(width: 375, height: 83))
    }
}

private extension DateRangeView {
    enum Constants {
        static let buttonContentTop: CGFloat = 18
        static let buttonContentLeading: CGFloat = 16
        static let buttonContentBottom: CGFloat = 13
        static let buttonContentTrailing: CGFloat = 16
    }
}
