import SwiftUI

struct AnalyticsSessionsReportCard: View {
    /// Whether to show the call to action to enable Jetpack Stats.
    ///
    let showJetpackStatsCTA: Bool

    /// Enables Jetpack Stats remotely.
    ///
    let enableJetpackStats: () async -> Void

    /// Tracks when the Jetpack Stats CTA is shown.
    ///
    let trackJetpackStatsCTAShown: () -> Void

    /// Whether sessions data is available.
    ///
    let isSessionsDataAvailable: Bool

    /// View model for the Sessions report card, when data is available.
    ///
    let viewModel: SessionsReportCardViewModel

    @State private var isEnablingJetpackStats = false

    var body: some View {
        if showJetpackStatsCTA {
            AnalyticsCTACard(title: Localization.title,
                             message: Localization.sessionsCTAMessage,
                             buttonLabel: Localization.sessionsCTAButton,
                             isLoading: $isEnablingJetpackStats) {
                isEnablingJetpackStats = true
                await enableJetpackStats()
                isEnablingJetpackStats = false
            }.onAppear {
                trackJetpackStatsCTAShown()
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
    AnalyticsSessionsReportCard(showJetpackStatsCTA: false,
                                enableJetpackStats: {},
                                trackJetpackStatsCTAShown: {},
                                isSessionsDataAvailable: true,
                                viewModel: .init(currentOrderStats: nil,
                                                 siteStats: nil))
}
