/// Models a pair of `siteID` and Shipment Tracking Provider name
/// These entities will be serialised to a plist file
///

public struct Announcement: Codable {
    public let appVersion: String
    public let features: [Feature]
    public let announcementVersion: String

    public init(appVersion: String, features: [Feature], announcementVersion: String) {
        self.appVersion = appVersion
        self.features = features
        self.announcementVersion = announcementVersion
    }
}
