/// Models an Announcement that contains a list of released features of the app
/// It has also a displayed property responsible to let us know if this was already shown to user when the application starts
///
/// These entities will be serialised to a plist file

public struct Announcement: Codable {
    public let appVersionName: String
    public let minimumAppVersion: String
    public let maximumAppVersion: String
    public let appVersionTargets: [String]
    public let detailsUrl: String
    public let announcementVersion: String
    public let isLocalized: Bool
    public let responseLocale: String
    public let features: [Feature]
    public let displayed: Bool

    public init(appVersionName: String,
                minimumAppVersion: String,
                maximumAppVersion: String,
                appVersionTargets: [String],
                detailsUrl: String,
                announcementVersion: String,
                isLocalized: Bool,
                responseLocale: String,
                features: [Feature],
                displayed: Bool) {
        self.appVersionName = appVersionName
        self.minimumAppVersion = minimumAppVersion
        self.maximumAppVersion = maximumAppVersion
        self.appVersionTargets = appVersionTargets
        self.detailsUrl = detailsUrl
        self.announcementVersion = announcementVersion
        self.isLocalized = isLocalized
        self.responseLocale = responseLocale
        self.features = features
        self.displayed = displayed
    }
}
