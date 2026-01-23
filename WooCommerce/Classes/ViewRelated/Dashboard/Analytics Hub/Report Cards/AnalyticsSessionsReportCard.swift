import SwiftUI

struct AnalyticsSessionsReportCard: View {
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
                Task { @MainActor in
                    isEnablingJetpackStats = true
                    await viewModel.enableJetpackStats()
                    isEnablingJetpackStats = false
                }
            }.onAppear {
                viewModel.trackJetpackStatsCTAShown()
            }
        } else if !viewModel.isSessionsDataAvailable {
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
                                                          comment: "This message appears in the Analytics Hub's Sessions section when Jetpack Stats is disabled, informing users they need to enable it to view session analytics data for their store.")
        static let sessionsCTAButton = NSLocalizedString("analyticsHub.jetpackStatsCTA.buttonLabel",
                                                         value: "Enable Jetpack Stats",
                                                         comment: "This is the label for a button that appears in the Analytics Hub's Sessions report card when Jetpack Stats is disabled. When tapped, it enables Jetpack Stats functionality to allow users to view their store's session analytics data.")
    }
}

#Preview("Sessions report card") {
    AnalyticsSessionsReportCard(viewModel: .init(siteID: 123,
                                                 currentOrderStats: SessionsReportCardViewModel.sampleOrderStats(),
                                                 siteStats: SessionsReportCardViewModel.sampleSiteStats(),
                                                 timeRange: .today,
                                                 isJetpackStatsDisabled: false,
                                                 updateSiteStatsData: {}))
}
