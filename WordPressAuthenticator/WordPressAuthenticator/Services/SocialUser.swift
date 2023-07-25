public struct SocialUser {

    /// The social service a user comes from
    public enum Service {
        case google
        case apple
    }

    public let email: String
    public let fullName: String
    public let service: Service
}
