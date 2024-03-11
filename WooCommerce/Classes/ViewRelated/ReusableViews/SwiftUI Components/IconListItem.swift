import Kingfisher
import SwiftUI

/// Represent a row with a title, subtitle and icon. Used to fill up reports such as What's New in WooCommerce
///
struct IconListItem: View {

    /// Represents an icon to be displayed. Base64 or Remote (from web)
    enum Icon {
        /// Base64 icon
        case base64(UIImage)

        case adaptiveBase64(anyAppearance: UIImage, dark: UIImage?)

        /// Icon that comes from an URL
        case remote(URL)

        /// Adaptive (light/dark mode) remote image, with URLs for one or more parts
        case adaptiveRemote(anyAppearance: URL, dark: URL?)

        /// Return an Image for base64 or a FKImage in case of a remote one
        @ViewBuilder
        func getImage() -> some View {
            switch self {
            case .base64(let image):
                Image(uiImage: image)
                    .resizable()
            case .adaptiveBase64(let anyAppearance, let dark):
                AdaptiveImage(anyAppearance: anyAppearance, dark: dark)
            case .remote(let url):
                KFImage(url)
                    .resizable()
            case .adaptiveRemote(let anyAppearance, let dark):
                AdaptiveAsyncImage(anyAppearanceUrl: anyAppearance,
                                   darkUrl: dark,
                                   scale: 3) { imagePhase in
                    switch imagePhase {
                    case .success(let image):
                        image.scaledToFit()
                    case .empty:
                        Image(systemName: Constants.placeholderImageName)
                            .font(.system(size: Layout.placeholderSize))
                            .redacted(reason: .placeholder)
                    case .failure:
                        Image(systemName: Constants.placeholderImageName)
                            .font(.system(size: Layout.placeholderSize))
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
        HStack(alignment: .top, spacing: Layout.contentSpacing) {
            icon?.getImage()
                .frame(width: Layout.iconSize.width, height: Layout.iconSize.height)
                .accessibility(hidden: true)
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
        static let placeholderSize: CGFloat = 40
    }

    enum Constants {
        static let placeholderImageName: String = "list.bullet.circle.fill"
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
