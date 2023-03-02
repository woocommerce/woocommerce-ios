import Foundation

/// View model for `WPComPasswordLoginView`.
///
final class WPComPasswordLoginViewModel: ObservableObject {

    /// Title of the view.
    let titleString: String

    /// Entered password
    @Published var password: String = ""

    /// Email address of the WPCom account
    let email: String

    @Published private(set) var avatarURL: URL?

    init(email: String, requiresConnectionOnly: Bool) {
        self.email = email
        self.titleString = requiresConnectionOnly ? Localization.connectJetpack : Localization.installJetpack
        avatarURL = gravatarUrl(of: email)
    }
}

// MARK: - Helpers
private extension WPComPasswordLoginViewModel {
    /// Constructs Gravatar URL from an email.
    /// Ref: https://en.gravatar.com/site/implement/images/
    func gravatarUrl(of email: String) -> URL? {
        let hash = gravatarHash(of: email)
        let targetURL = String(format: "%@/%@?d=%@&s=%d&r=%@", Constants.baseGravatarURL, hash, Constants.gravatarDefaultOption, Constants.imageSize, Constants.gravatarRating)
        return URL(string: targetURL)
    }

    func gravatarHash(of email: String) -> String {
        return email
            .lowercased()
            .trimmingCharacters(in: .whitespaces)
            .md5Hash()
    }
}

extension WPComPasswordLoginViewModel {
    enum Constants {
        static let imageSize = 80
        static let baseGravatarURL = "https://gravatar.com/avatar"
        static let gravatarRating = "g" // safest rating
        static let gravatarDefaultOption = "mp" // a simple, cartoon-style silhouetted outline of a person
    }
    enum Localization {
        static let installJetpack = NSLocalizedString(
            "Install Jetpack",
            comment: "Title for the WPCom magic link screen when Jetpack is not installed yet"
        )
        static let connectJetpack = NSLocalizedString(
            "Connect Jetpack",
            comment: "Title for the WPCom magic link screen when Jetpack is not connected yet"
        )
    }
}
