import SwiftUI

// MARK: - AnalyticsView
//
struct AnalyticsView: View {
    var body: some View {
        ZStack {
            VStack {
                DateRangeView(dateRangeText: "Today (Sep 10, 2020)", selectedRange: "Yesterday")
                Spacer()
            }
        }
        .navigationTitle(Localization.title)
    }
}

struct AnalyticsView_Previews: PreviewProvider {
    static var previews: some View {
        AnalyticsView()
    }
}

private extension AnalyticsView {
    enum Localization {
        static let title = NSLocalizedString("Analytics", comment: "Title of the analytics view.")
    }
}
