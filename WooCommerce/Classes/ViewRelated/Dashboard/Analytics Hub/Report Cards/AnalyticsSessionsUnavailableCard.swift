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
        static let title = NSLocalizedString("analyticsHub.sessionsCard.Title", value: "SESSIONS", comment: "Title for sessions section in the Analytics Hub")
        static let message = NSLocalizedString("analyticsHub.sessionsCard.dataUnavailable.Message",
                                               value: "Session data unavailable",
                                               comment: "Message when session data is unavailable in the Analytics Hub")
        static let description = NSLocalizedString("analyticsHub.sessionsCard.dataUnavailable.Description",
                                                   value: "Session analytics rely on unique visitor counts not available for custom date ranges.",
                                                   comment: "Description when session data is unavailable in the Analytics Hub")
    }
}

#Preview {
    AnalyticsSessionsUnavailableCard()
}
