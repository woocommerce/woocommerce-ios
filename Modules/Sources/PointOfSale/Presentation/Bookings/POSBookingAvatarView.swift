import SwiftUI

struct POSBookingAvatarView: View {
    let imageURL: String?
    let resourceName: String?

    var body: some View {
        if let imageURL, let url = URL(string: imageURL) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: Constants.avatarSize, height: Constants.avatarSize)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.posOutlineVariant, lineWidth: Constants.borderWidth)
                        )
                default:
                    initialsPlaceholder
                }
            }
        } else if resourceName != nil {
            initialsPlaceholder
        }
    }

    @ViewBuilder
    private var initialsPlaceholder: some View {
        if let initials = Self.initials(from: resourceName) {
            Circle()
                .fill(Color.posOutline)
                .frame(width: Constants.avatarSize, height: Constants.avatarSize)
                .overlay(
                    Text(initials)
                        .font(.system(size: Constants.initialsSize, weight: .medium))
                        .foregroundStyle(Color.posOnPrimary)
                )
        }
    }

    static func initials(from name: String?) -> String? {
        guard let name, !name.isEmpty else { return nil }
        let components = name.split(separator: " ")
        if components.count >= 2 {
            return String(components[0].prefix(1) + components[1].prefix(1)).uppercased()
        }
        return String(components[0].prefix(1)).uppercased()
    }
}

private enum Constants {
    static let avatarSize: CGFloat = 24
    static let borderWidth: CGFloat = 1
    static let initialsSize: CGFloat = 10
}
