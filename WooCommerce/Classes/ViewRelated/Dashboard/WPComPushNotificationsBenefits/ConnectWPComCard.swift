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
            comment: "This is the title text displayed on a promotional card in the My Store dashboard screen that encourages users to connect their WooCommerce store to a WordPress.com account for push notifications about new orders."
        )
        static let subtitle = NSLocalizedString(
            "dashboardView.connectWPComCard.subtitle",
            value: "Connect your store to a WordPress.com account to get alerts for new orders and reviews.",
            comment: "This subtitle text appears on a promotional card in the My Store dashboard screen that encourages users to connect their WooCommerce store to a WordPress.com account for push notifications."
        )
        static let hideButton = NSLocalizedString(
            "dashboardView.connectWPComCard.hideButton",
            value: "Hide this content",
            comment: "This text appears as a button label on a promotional card in the My Store dashboard screen that encourages users to connect their store to WordPress.com for push notifications. When tapped, the button allows users to permanently dismiss this promotional content from their dashboard."
        )
    }
}

#Preview {
    ConnectWPComCard(setupAction: {}, hideAction: {})
}
