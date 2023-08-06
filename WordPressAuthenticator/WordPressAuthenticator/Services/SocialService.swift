/// Social service metadata.
public enum SocialService {

    public struct User {
        public let email: String
        public let fullName: String
    }

    public var user: User {
        switch self {
        case .google(let user): return user
        case .apple(let user): return user
        }
    }

    /// Google's Signup Linked Account
    ///
    case google(user: User)

    /// Apple's Signup Linked Account
    ///
    case apple(user: User)
}
