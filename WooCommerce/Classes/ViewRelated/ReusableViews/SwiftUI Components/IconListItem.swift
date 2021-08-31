import Kingfisher
import SwiftUI

/// Represent a row with a title, subtitle and icon. Used to fill up reports such as What's New in WooCommerce
///
struct IconListItem: View {
    let title: String
    let subtitle: String
    let iconUrl: String
    let icon: UIImage?

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            if let icon = icon {
                Image(uiImage: icon)
                    .resizable()
                    .frame(width: Constants.iconSize.width, height: Constants.iconSize.height)
            } else if let url = URL(string: iconUrl) {
                KFImage(url)
                    .resizable()
                    .frame(width: Constants.iconSize.width, height: Constants.iconSize.height)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold, design: .default))
                Text(subtitle)
                    .font(.system(size: 17, weight: .regular, design: .default))
                    .foregroundColor(subtitleColor)
            }
            Spacer()
        }
        .padding(.horizontal, 40)
        .padding(.vertical, 16)
    }

    var subtitleColor: Color {
        Color(UIColor { $0.userInterfaceStyle == .dark
            ? UIColor(red: 1, green: 1, blue: 1, alpha: 0.6)
            : UIColor(red: 0, green: 0, blue: 0, alpha: 0.6)
        })
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
        IconListItem(title: "Title", subtitle: "Subtitle", iconUrl: "https://s0.wordpress.com/i/store/mobile/plans-premium.png", icon: nil)
            .previewLayout(.fixed(width: 375, height: 100))
            .previewDisplayName("Regular Icon List Item")
            .environment(\.layoutDirection, .leftToRight)
    }
}
