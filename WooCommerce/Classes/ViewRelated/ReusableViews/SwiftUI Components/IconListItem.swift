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
            }
        }
    }

    let title: String
    let subtitle: String
    let icon: Icon?

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            icon?.getImage()
                .frame(width: Constants.iconSize.width, height: Constants.iconSize.height)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .headlineStyle()
                Text(subtitle)
                    .secondaryBodyStyle()
            }
            Spacer()
        }
        .padding(.horizontal, 40)
        .padding(.vertical, 16)
    }
}

private extension IconListItem {
    enum Constants {
        static let iconSize = CGSize(width: 40, height: 40)
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
