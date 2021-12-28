import SwiftUI

struct AnalyticsView: View {
    var body: some View {
        ZStack {
            VStack {
                DateRangeView(selectedRange: "Today")
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
