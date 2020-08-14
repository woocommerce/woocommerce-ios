
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

    /// Key/Value type to store feedback settings
    /// Key: A `String` to identify the feedback
    /// Value: A `FeedbackSetting` to store the feedback state
    public let feedbacks: [String: FeedbackSettings]

    public init(installationDate: Date?, feedbacks: [String: FeedbackSettings]) {
        self.installationDate = installationDate
        self.feedbacks = feedbacks
    }
}
