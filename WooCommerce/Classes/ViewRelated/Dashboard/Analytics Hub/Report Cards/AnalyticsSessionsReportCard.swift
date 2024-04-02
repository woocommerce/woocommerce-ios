import SwiftUI

struct AnalyticsSessionsReportCard: View {
    /// Whether sessions data is available.
    ///
    let isSessionsDataAvailable: Bool

    /// View model for the Sessions report card, when data is available.
    ///
    let viewModel: SessionsReportCardViewModel

    @State private var isEnablingJetpackStats = false

    var body: some View {
        if viewModel.showJetpackStatsCTA {
            AnalyticsCTACard(title: Localization.title,
                             message: Localization.sessionsCTAMessage,
                             buttonLabel: Localization.sessionsCTAButton,
                             isLoading: $isEnablingJetpackStats) {
                isEnablingJetpackStats = true
                await viewModel.enableJetpackStats()
                isEnablingJetpackStats = false
            }.onAppear {
                viewModel.trackJetpackStatsCTAShown()
            }
        } else if !isSessionsDataAvailable {
            AnalyticsSessionsUnavailableCard()
        } else {
            AnalyticsReportCard(viewModel: viewModel)
        }
    }
}

private extension AnalyticsSessionsReportCard {
    enum Localization {
        static let title = NSLocalizedString("SESSIONS", comment: "Title for sessions section in the Analytics Hub")
        static let sessionsCTAMessage = NSLocalizedString("analyticsHub.jetpackStatsCTA.message",
                                                          value: "Enable Jetpack Stats to see your store's session analytics.",
                                                          comment: "Text displayed in the Analytics Hub when the Jetpack Stats module is disabled")
        static let sessionsCTAButton = NSLocalizedString("analyticsHub.jetpackStatsCTA.buttonLabel",
                                                         value: "Enable Jetpack Stats",
                                                         comment: "Label for button to enable Jetpack Stats")
    }
}

#Preview("Sessions report card") {
    AnalyticsSessionsReportCard(isSessionsDataAvailable: true,
                                viewModel: .init(siteID: 123,
                                                 currentOrderStats: SessionsReportCardViewModel.sampleOrderStats(),
                                                 siteStats: SessionsReportCardViewModel.sampleSiteStats(),
                                                 isJetpackStatsDisabled: false,
                                                 updateSiteStatsData: {}))
}
