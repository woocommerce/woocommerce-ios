import SwiftUI

/// Reusable card for the Analytics Hub with a call to action.
///
struct AnalyticsCTACard: View {

    /// Title for the card
    ///
    let title: String

    /// Message for the card
    ///
    let message: String

    /// Label for the call to action button
    ///
    let buttonLabel: String

    /// Whether the call to action button is loading
    ///
    @Binding var isLoading: Bool

    /// Action for the call to action button
    ///
    let buttonAction: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.titleSpacing) {
            Text(title)
                .foregroundColor(Color(.text))
                .footnoteStyle()

            Text(message)
                .foregroundColor(Color(.text))
                .bodyStyle()

            Button {
                buttonAction()
            } label: {
                Text(buttonLabel)
            }
            .buttonStyle(PrimaryLoadingButtonStyle(isLoading: isLoading))
        }
        .padding(Layout.cardPadding)
    }
}

// MARK: Constants
private extension AnalyticsCTACard {
    enum Layout {
        static let titleSpacing: CGFloat = 24
        static let cardPadding: CGFloat = 16
    }
}

#Preview {
    AnalyticsCTACard(title: "SESSIONS",
                     message: "Enable Jetpack Stats to see your store's session analytics.",
                     buttonLabel: "Enable Jetpack Stats",

                     isLoading: .constant(false),
                     buttonAction: {})
}
