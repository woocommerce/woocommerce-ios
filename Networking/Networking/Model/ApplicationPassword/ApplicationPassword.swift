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

    /// App ID
    ///
    public let appID: String

    public init(wpOrgUsername: String, password: Secret<String>, uuid: String, appID: String) {
        self.password = password
        self.uuid = uuid
        self.appID = appID
        self.wpOrgUsername = wpOrgUsername
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        guard let wpOrgUsername = decoder.userInfo[.wpOrgUsername] as? String else {
            throw ApplicationPasswordDecodingError.missingWpOrgUsername
        }

        let password = try container.decodeIfPresent(String.self, forKey: .password) ?? ""
        let uuid = try container.decode(String.self, forKey: .uuid)
        let appID = try container.decode(String.self, forKey: .appID)
        self.init(wpOrgUsername: wpOrgUsername, password: Secret(password), uuid: uuid, appID: appID)
    }

    enum CodingKeys: String, CodingKey {
        case password
        case uuid
        case appID = "app_id"
    }
}

// MARK: - Decoding Errors
//
enum ApplicationPasswordDecodingError: Error {
    case missingWpOrgUsername
}
