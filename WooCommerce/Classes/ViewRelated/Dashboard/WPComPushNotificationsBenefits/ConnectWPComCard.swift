import SwiftUI

/// A card prompting users to connect their store to WordPress.com for push notifications.
struct ConnectWPComCard: View {

    /// Closure invoked when the card is tapped
    var setupAction: () -> Void

    /// Closure invoked when the hide button is tapped
    var hideAction: () -> Void

    @ScaledMetric private var scale: CGFloat = 1.0

    var body: some View {
        HStack {
            Image(uiImage: .connectWPComImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: Layout.iconHeight * scale)
            VStack(alignment: .leading) {
                Text(Localization.title)
                    .font(.body)
                    .fontWeight(.semibold)
                Text(Localization.subtitle)
                    .font(.callout)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            VStack {
                Menu {
                    Button(Localization.hideButton) {
                        hideAction()
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundStyle(Color.secondary)
                        .padding(.leading, Layout.padding)
                }
                Spacer()
            }
        }
        .padding(Layout.padding)
        .background(Color(.listForeground(modal: false)))
        .clipShape(RoundedRectangle(cornerSize: Layout.cornerSize))
        .padding(.horizontal, Layout.padding)
        .contentShape(Rectangle())
        .onTapGesture {
            setupAction()
        }
    }
}

private extension ConnectWPComCard {
    enum Layout {
        static let padding: CGFloat = 16
        static let iconHeight: CGFloat = 35
        static let cornerSize = CGSize(width: 8.0, height: 8.0)
    }

    enum Localization {
        static let title = NSLocalizedString(
            "dashboardView.connectWPComCard.title",
            value: "Never miss a new order",
            comment: "Title of the Connect WPCom card on My Store screen"
        )
        static let subtitle = NSLocalizedString(
            "dashboardView.connectWPComCard.subtitle",
            value: "Enable push notifications to stay on top of new orders and reviews.",
            comment: "Subtitle of the Connect WPCom card on My Store screen"
        )
        static let hideButton = NSLocalizedString(
            "dashboardView.connectWPComCard.hideButton",
            value: "Hide this content",
            comment: "Button to hide the Connect WPCom card from the My Store screen"
        )
    }
}

#Preview {
    ConnectWPComCard(setupAction: {}, hideAction: {})
}
