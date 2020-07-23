
import Foundation

/// An encodable/decodable data structure that can be used to save files. This contains
/// miscellaneous app settings.
///
/// Sometimes I wonder if `AppSettingsStore` should just use one plist file. Maybe things will
/// be simpler?
///
public struct GeneralAppSettings: Codable, Equatable {
    /// The known `Date` that the app was installed.
    ///
    /// Note that this is not accurate because this property/setting was created when we have
    /// thousands of users already.
    ///
    public let installationDate: Date?

    /// The last time that the user interacted with the in-app feedback (https://git.io/JJ8i0).
    ///
    public let lastFeedbackDate: Date?

    public init(installationDate: Date?, lastFeedbackDate: Date?) {
        self.installationDate = installationDate
        self.lastFeedbackDate = lastFeedbackDate
    }
}
