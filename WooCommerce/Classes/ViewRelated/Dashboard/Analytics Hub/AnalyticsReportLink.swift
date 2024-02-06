import SwiftUI

struct AnalyticsReportLink: View {
    @Binding var showingWebReport: Bool
    let reportViewModel: WPAdminWebViewModel

    var body: some View {
        Button {
            showingWebReport = true
        } label: {
            Text(Localization.seeReport)
                .bodyStyle()
                .frame(maxWidth: .infinity, alignment: .leading)
            DisclosureIndicator()
        }
        .sheet(isPresented: $showingWebReport) {
            WooNavigationSheet(viewModel: .init(navigationTitle: reportViewModel.title, done: {
                showingWebReport = false
            })) {
                AuthenticatedWebView(isPresented: $showingWebReport, viewModel: reportViewModel)
            }
        }
    }
}

// MARK: Constants
private extension AnalyticsReportLink {
    enum Localization {
        static let seeReport = NSLocalizedString("analyticsHub.reportCard.webReport",
                                                 value: "See Report",
                                                 comment: "Button label to show an analytics report in the Analytics Hub")
    }
}

#Preview {
    AnalyticsReportLink(showingWebReport: .constant(false), reportViewModel: .init(initialURL: URL(string: "https://woo.com/")!))
        .previewLayout(.sizeThatFits)
}
