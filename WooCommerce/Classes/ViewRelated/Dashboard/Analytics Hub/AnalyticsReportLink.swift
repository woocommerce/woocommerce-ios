import SwiftUI

struct AnalyticsReportLink: View {
    @Binding var showingWebReport: Bool

    /// View model for the report webview
    let reportViewModel: AnalyticsReportLinkViewModel

    var body: some View {
        Button {
            reportViewModel.onWebViewOpen()
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
    AnalyticsReportLink(showingWebReport: .constant(false),
                        reportViewModel: .init(reportType: .revenue,
                                               period: .today,
                                               webViewTitle: "Revenue Report",
                                               reportURL: URL(string: "https://woo.com/")!,
                                               usageTracksEventEmitter: StoreStatsUsageTracksEventEmitter()))
        .previewLayout(.sizeThatFits)
}
