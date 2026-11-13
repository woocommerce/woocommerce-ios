import SwiftUI
import protocol WooFoundation.Analytics
import struct Yosemite.DashboardCard

/// Shared error view for dashboard cards
struct DashboardCardErrorView: View {
    @State private var showingSupportForm = false

    private let onRetry: () -> Void

    private var errorMessage: NSAttributedString {
        let contactSupportText = Localization.contactSupport
        let content = String.localizedStringWithFormat(Localization.errorMessage, contactSupportText)
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center

        let mutableAttributedText = NSMutableAttributedString(
            string: content,
            attributes: [.font: UIFont.body,
                         .foregroundColor: UIColor.text,
                         .paragraphStyle: paragraph]
        )

        mutableAttributedText.highlightSubstring(textToFind: contactSupportText)
        return mutableAttributedText
    }

    init(onRetry: @escaping () -> Void) {
        self.onRetry = onRetry
    }

    var body: some View {
        VStack(alignment: .center, spacing: Layout.padding) {
            Image(uiImage: .noConnectionImage)
            Text(Localization.errorTitle)
                .headlineStyle()
            AttributedText(errorMessage)
                .contentShape(Rectangle())
                .onTapGesture {
                    showingSupportForm = true
                }
            Button(Localization.retry) {
                onRetry()
            }
            .buttonStyle(SecondaryButtonStyle())
        }
        .frame(maxWidth: .infinity)
        .sheet(isPresented: $showingSupportForm) {
            supportForm
        }
    }

    private var supportForm: some View {
        NavigationView {
            SupportForm(isPresented: $showingSupportForm,
                        viewModel: SupportFormViewModel(mobileStatusReportProvider: MobileStatusReportProvider()))
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(Localization.done) {
                        showingSupportForm = false
                    }
                }
            }
        }
        .navigationViewStyle(.stack)
    }
}

/// Lays out a dashboard card's time range bar above its content, or above the error view when loading fails.
/// The bar stays visible on errors so merchants can recover by switching to another range.
struct DashboardCardRangedContent<RangeBar: View, Content: View>: View {
    private let retryEvent: WooAnalyticsEvent
    private let hasError: Bool
    private let reload: @MainActor () async -> Void
    private let analytics: Analytics
    private let rangeBar: RangeBar
    private let content: Content

    init(cardType: DashboardCard.CardType,
         hasError: Bool,
         reload: @escaping @MainActor () async -> Void,
         analytics: Analytics = ServiceLocator.analytics,
         @ViewBuilder rangeBar: () -> RangeBar,
         @ViewBuilder content: () -> Content) {
        self.retryEvent = .DynamicDashboard.cardRetryTapped(type: cardType)
        self.hasError = hasError
        self.reload = reload
        self.analytics = analytics
        self.rangeBar = rangeBar()
        self.content = content()
    }

    var body: some View {
        // Group keeps these rows in the card's own stack, so its spacing still applies between them.
        Group {
            rangeBar
            Divider()
            if hasError {
                DashboardCardErrorView(onRetry: retry)
                    .padding(.horizontal, DashboardCardErrorView.Layout.padding)
            } else {
                content
            }
        }
    }

    private func retry() {
        analytics.track(event: retryEvent)
        Task { await reload() }
    }
}

private extension DashboardCardErrorView {
    enum Layout {
        static let padding: CGFloat = 16
    }

    enum Localization {
        static let errorTitle = NSLocalizedString(
            "dashboardCardErrorView.errorTitle",
            value: "Unable to load data",
            comment: "The title of the error view when failed to load a Dashboard card"
        )
        static let errorMessage = NSLocalizedString(
            "dashboardCardErrorView.errorMessage",
            value: "Try reloading this card. If the issue persists, please %1$@.",
            comment: "The info of the error view when failed to load store statistics on the Dashboard screen. " +
            "The placeholder is a link to contact support. " +
            "Reads as: Try reloading this card. If the issue persists, please contact us."
        )
        static let contactSupport = NSLocalizedString(
            "dashboardCardErrorView.contactSupport",
            value: "contact support",
            comment: "Link to open the support form. Should be lowercased."
        )
        static let retry = NSLocalizedString(
            "dashboardCardErrorView.retry",
            value: "Retry",
            comment: "Button to reload the dashboard card on the Dashboard screen"
        )
        static let done = NSLocalizedString(
            "dashboardCardErrorView.dismissSupport",
            value: "Done",
            comment: "Button to dismiss the support form from the Dashboard generic error card."
        )
    }
}

#Preview {
    DashboardCardErrorView(onRetry: {})
}
