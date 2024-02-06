import SwiftUI

struct AnalyticsHubReportLink: View {
    @Binding var showingWebReport: Bool
    let reportViewModel: WPAdminWebViewModel

    var body: some View {
        VStack(spacing: Layout.spacing) {
            Divider()
            Button {
                showingWebReport = true
            } label: {
                Text(Localization.seeReport)
                    .frame(maxWidth: .infinity, alignment: .leading)
                DisclosureIndicator()
            }
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
private extension AnalyticsHubReportLink {
    enum Localization {
        static let seeReport = NSLocalizedString("analyticsHub.reportCard.webReport",
                                                 value: "See Report",
                                                 comment: "Button label to show an analytics report in the Analytics Hub")
    }

    enum Layout {
        static let spacing: CGFloat = 16
    }
}

#Preview {
    AnalyticsHubReportLink(showingWebReport: .constant(true), reportViewModel: .init(initialURL: URL(string: "https://example.com/")!))
        .previewLayout(.sizeThatFits)
}
