import SwiftUI

struct AnalyticsView: View {
    var body: some View {
        ZStack {
            Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
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
