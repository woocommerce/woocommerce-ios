import Kingfisher
import SwiftUI

/// Represent a row with a title, subtitle and icon. Used to fill up reports such as What's New in WooCommerce
///
struct IconListItem: View {

    /// Represents an icon to be displayed. Base64 or Remote (from web)
    enum Icon {
        /// Base64 icon
        case base64(UIImage)

        /// Icon that comes from an URL
        case remote(URL)

        /// Adaptive (light/dark mode) remote image, with URLs for one or more parts
        case adaptiveRemote(universal: URL, dark: URL?)

        /// Return an Image for base64 or a FKImage in case of a remote one
        @ViewBuilder
        func getImage() -> some View {
            switch self {
            case .base64(let image):
                Image(uiImage: image)
                    .resizable()
            case .remote(let url):
                KFImage(url)
                    .resizable()
            case .adaptiveRemote(let universal, let dark):
                AdaptiveAsyncImage(lightUrl: universal, darkUrl: dark, scale: 3) { imagePhase in
                    switch imagePhase {
                    case .success(let image):
                        image.scaledToFit()
                    case .empty:
                        Image(systemName: "list.bullet.circle.fill").redacted(reason: .placeholder)
                    case .failure:
                        EmptyView()
                    @unknown default:
                        EmptyView()
                    }
                }
            }
        }
    }

    let title: String
    let subtitle: String
    let icon: Icon?

    var body: some View {
        HStack(alignment: .center, spacing: Layout.contentSpacing) {
            VStack {
                icon?.getImage()
                    .frame(width: Layout.iconSize.width, height: Layout.iconSize.height)
                    .accessibility(hidden: true)
                Spacer()
            }
            VStack(alignment: .leading, spacing: Layout.innerSpacing) {
                Text(title)
                    .headlineStyle()
                Text(subtitle)
                    .secondaryBodyStyle()
            }
            Spacer()
        }
        .padding(.horizontal, Layout.horizontalPadding)
    }
}

private extension IconListItem {
    enum Layout {
        static let iconSize = CGSize(width: 40, height: 40)
        static let contentSpacing: CGFloat = 16
        static let innerSpacing: CGFloat = 2
        static let horizontalPadding: CGFloat = 40
    }
}

// MARK: - Preview
struct IconListItem_Previews: PreviewProvider {
    static var previews: some View {
        IconListItem(title: "Title",
                     subtitle: "Subtitle",
                     icon: .remote(URL(string: "https://s0.wordpress.com/i/store/mobile/plans-premium.png")!))
            .previewLayout(.fixed(width: 375, height: 100))
            .previewDisplayName("Regular Icon List Item")
            .environment(\.layoutDirection, .leftToRight)
    }
}
