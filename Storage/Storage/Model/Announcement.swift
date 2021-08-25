public struct Announcement: Codable {
    public let appVersion: String
    public let features: [Feature]

    public init(appVersion: String, features: [Feature]) {
        self.appVersion = appVersion
        self.features = features
    }
}
