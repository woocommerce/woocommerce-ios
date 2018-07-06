import GoogleSignIn

// MARK: - Social Services Metadata
//
public enum SocialService {

    /// Google's Signup Linked Account
    ///
    case google(user: GIDGoogleUser)
}
