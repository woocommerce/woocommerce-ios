import Kingfisher
import SwiftUI

struct POSBookingAvatarView: View {
    let imageURL: String?
    let resourceName: String?

    private var fillColor: Color {
        Color(light: .posDefault, dark: .posSurfaceDim)
    }

    private var textColor: Color {
        Color(light: .posOnSurfaceVariantLowest, dark: .posOnSurfaceVariantHighest)
    }

    var body: some View {
        if let imageURL, let url = URL(string: imageURL) {
            KFImage
                .url(url)
                .placeholder {
                    ghostAvatar
                }
                .resizable()
                .scaledToFill()
                .frame(width: Constants.avatarSize, height: Constants.avatarSize)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(fillColor, lineWidth: Constants.borderWidth)
                )
        } else if resourceName != nil {
            initialsPlaceholder
        }
    }

    private var ghostAvatar: some View {
        Circle()
            .fill(Color.posOnSurfaceVariantLowest)
            .frame(width: Constants.avatarSize, height: Constants.avatarSize)
            .shimmering()
    }

    @ViewBuilder
    private var initialsPlaceholder: some View {
        if let initials = POSAvatarInitialsFormatter.initials(from: resourceName) {
            Circle()
                .fill(fillColor)
                .frame(width: Constants.avatarSize, height: Constants.avatarSize)
                .overlay(
                    Text(initials)
                        .font(.system(size: Constants.initialsSize, weight: .medium))
                        .foregroundStyle(textColor)
                )
        }
    }
}

private enum Constants {
    static let avatarSize: CGFloat = 24
    static let borderWidth: CGFloat = 1
    static let initialsSize: CGFloat = 10
}
