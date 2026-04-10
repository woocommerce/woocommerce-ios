import SwiftUI
import Kingfisher

struct WPComLoginGravatarView: View {
    let email: String
    let gravatarURL: URL?

    var body: some View {
        HStack(spacing: Constants.spacing) {
            KFImage(gravatarURL)
                .resizable()
                .clipShape(Circle())
                .frame(width: Constants.avatarSize, height: Constants.avatarSize)

            Text(email)

            Spacer()
        }
        .padding(Constants.avatarPadding)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(.gray, lineWidth: 1)
        )
    }
}

private extension WPComLoginGravatarView {
    enum Constants {
        static let spacing: CGFloat = 16
        static let avatarSize: CGFloat = 32
        static let avatarPadding: EdgeInsets = .init(top: 8, leading: 16, bottom: 8, trailing: 16)
    }
}

#Preview {
    WPComLoginGravatarView(
        email: "example@example.com",
        gravatarURL: URL(string: "https://www.gravatar.com/avatar/example")
    )
}
