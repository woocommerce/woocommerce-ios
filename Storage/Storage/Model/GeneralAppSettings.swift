
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
    /// Key: A `FeedbackType` to identify the feedback
    /// Value: A `FeedbackSetting` to store the feedback state
    public let feedbacks: [FeedbackType: FeedbackSettings]

    public init(installationDate: Date?, feedbacks: [FeedbackType: FeedbackSettings]) {
        self.installationDate = installationDate
        self.feedbacks = feedbacks
    }

    /// Returns the status of a given feedback type. If the feedback is not stored in the feedback array. it is assumed that it has a pending status.
    ///
    public func feedbackStatus(of type: FeedbackType) -> FeedbackSettings.Status {
        guard let feedbackSetting = feedbacks[type] else {
            return .pending
        }

        return feedbackSetting.status
    }

    /// Returns a new instance of `GeneralAppSettings` with the provided feedback seetings updated.
    ///
    public func replacing(feedback: FeedbackSettings) -> GeneralAppSettings {
        let updatedFeedbacks = feedbacks.merging([feedback.name: feedback]) {
            _, new in new
        }

        return GeneralAppSettings(installationDate: installationDate, feedbacks: updatedFeedbacks)
    }
}
