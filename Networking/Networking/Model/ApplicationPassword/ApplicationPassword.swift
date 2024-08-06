#if canImport(WordPressShared)
import WordPressShared
#endif

public struct ApplicationPassword: Codable, Equatable {
    /// WordPress org username that the application password belongs to
    ///
    public let wpOrgUsername: String

    /// Application password
    ///
    public let password: Secret<String>

    /// UUID
    ///
    public let uuid: String

    public init(wpOrgUsername: String, password: Secret<String>, uuid: String) {
        self.password = password
        self.uuid = uuid
        self.wpOrgUsername = wpOrgUsername
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Search for `wpOrgUsername` either in the decoder or in the user info
        let wpOrgUsername: String? = {
            return try? container.decodeIfPresent(String.self, forKey: .wpOrgUsername) ?? decoder.userInfo[.wpOrgUsername] as? String
        }()

        guard let wpOrgUsername else {
            throw ApplicationPasswordDecodingError.missingWpOrgUsername
        }

        let password = try container.decodeIfPresent(String.self, forKey: .password) ?? ""
        let uuid = try container.decode(String.self, forKey: .uuid)
        self.init(wpOrgUsername: wpOrgUsername, password: Secret(password), uuid: uuid)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(wpOrgUsername, forKey: .wpOrgUsername)
        try container.encodeIfPresent(password.secretValue, forKey: .password)
        try container.encodeIfPresent(uuid, forKey: .uuid)
    }

    enum CodingKeys: String, CodingKey {
        case wpOrgUsername
        case password
        case uuid
    }
}

// MARK: - Decoding Errors
//
enum ApplicationPasswordDecodingError: Error {
    case missingWpOrgUsername
}

// Add equatable conformance to Secret when possible
extension Secret: Equatable where Self.RawValue: Equatable {}
