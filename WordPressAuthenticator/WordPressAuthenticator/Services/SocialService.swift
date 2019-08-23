import GoogleSignIn

// MARK: - Social Services Metadata
//
public enum SocialService {

    /// Google's Signup Linked Account
    ///
    case google(user: GIDGoogleUser)
    
    /// Apple's Signup Linked Account
    ///
    case apple(user: AppleUser)
}

// Struct to contain information relevant to an Apple ID account.
public struct AppleUser {
    public var email: String
    public var fullName: String
}
