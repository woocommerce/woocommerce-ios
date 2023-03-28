import GoogleSignIn

// MARK: - Social Services Metadata
//
public enum SocialService {

    public struct User {
        public let email: String
        public let fullName: String
    }

    /// Google's Signup Linked Account
    ///
    case google(user: User)

    /// Apple's Signup Linked Account
    ///
    case apple(user: User)
}
