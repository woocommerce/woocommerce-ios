import SwiftUI

struct AnalyticsSessionsUnavailableCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Layout.titleSpacing) {
            Text(Localization.title)
                .foregroundColor(Color(.text))
                .footnoteStyle()

            Grid(alignment: .leading) {
                GridRow {
                    Image(uiImage: .exclamationImage)
                        .foregroundColor(Color(.error))
                    Text(Localization.message)
                        .headlineStyle()
                }
                GridRow {
                    Spacer().fixedSize()
                    Text(Localization.description)
                        .bodyStyle()
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Layout.cardPadding)
            .overlay(RoundedRectangle(cornerRadius: Layout.cornerRadius)
                .stroke(Color(.systemGray4)))
        }
        .padding(Layout.cardPadding)
    }
}

// MARK: Constants
private extension AnalyticsSessionsUnavailableCard {
    enum Layout {
        static let titleSpacing: CGFloat = 24
        static let cardPadding: CGFloat = 16
        static let cornerRadius: CGFloat = 8
    }

    enum Localization {
        static let title = NSLocalizedString("analyticsHub.sessionsCard.Title", value: "SESSIONS", comment: "This text appears as the title/header for the sessions analytics card in the WooCommerce Analytics Hub dashboard, displayed when session data is unavailable for custom date ranges.")
        static let message = NSLocalizedString("analyticsHub.sessionsCard.dataUnavailable.Message",
                                               value: "Session data unavailable",
                                               comment: "This message appears on a card in the Analytics Hub section when session data cannot be displayed. It serves as a brief status message to inform users that the session analytics information is currently unavailable.")
        static let description = NSLocalizedString("analyticsHub.sessionsCard.dataUnavailable.Description",
                                                   value: "Session analytics rely on unique visitor counts not available for custom date ranges.",
                                                   comment: "This text appears as an explanatory description on the Analytics Hub screen when session data is unavailable for custom date ranges, helping users understand why the sessions analytics card cannot display data.")
    }
}

#Preview {
    AnalyticsSessionsUnavailableCard()
}
