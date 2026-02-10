import SwiftUI

struct POSBookingAvatarView: View {
    let imageURL: String?

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
                    EmptyView()
                }
            }
        }
    }
}

private enum Constants {
    static let avatarSize: CGFloat = 24
    static let borderWidth: CGFloat = 1
}
