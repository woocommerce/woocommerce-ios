import SwiftUI

// MARK: - DateRangeSheet
//
struct DateRangeSheet: View {
    var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor.listBackground).edgesIgnoringSafeArea(.all)
                VStack(alignment: .leading, spacing: 0, content: {
                    Spacer()
                        .frame(height: 8)
                    // Loop through the date range options
                    Spacer()
                })
            }
            .navigationTitle(Localization.title)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct DateRangeSheet_Previews: PreviewProvider {
    static var previews: some View {
        DateRangeSheet()
    }
}

private extension DateRangeSheet {
    enum Localization {
        static let title = NSLocalizedString("Select Date Range", comment: "Title of date range sheet.")
    }
}
