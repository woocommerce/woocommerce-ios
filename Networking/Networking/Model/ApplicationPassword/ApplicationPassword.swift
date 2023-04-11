import WordPressShared

public struct ApplicationPassword: Decodable {
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

        guard let wpOrgUsername = decoder.userInfo[.wpOrgUsername] as? String else {
            throw ApplicationPasswordDecodingError.missingWpOrgUsername
        }

        let password = try container.decodeIfPresent(String.self, forKey: .password) ?? ""
        let uuid = try container.decode(String.self, forKey: .uuid)
        self.init(wpOrgUsername: wpOrgUsername, password: Secret(password), uuid: uuid)
    }

    enum CodingKeys: String, CodingKey {
        case password
        case uuid
    }
}

// MARK: - Decoding Errors
//
enum ApplicationPasswordDecodingError: Error {
    case missingWpOrgUsername
}
