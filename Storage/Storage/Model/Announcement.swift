/// Models an Announcement that containts a list of released features of the app
/// It has also a displayed property responsible to let us know if this was alreasy shown to user when the application starts
///
/// These entities will be serialised to a plist file

public struct Announcement: Codable {
    public let appVersion: String
    public let features: [Feature]
    public let announcementVersion: String
    public let displayed: Bool

    public init(appVersion: String,
                features: [Feature],
                announcementVersion: String,
                displayed: Bool) {
        self.appVersion = appVersion
        self.features = features
        self.announcementVersion = announcementVersion
        self.displayed = displayed
    }
}
