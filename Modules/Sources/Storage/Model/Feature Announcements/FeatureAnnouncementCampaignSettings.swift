import Foundation
import Codegen

public struct FeatureAnnouncementCampaignSettings: Codable, Equatable, GeneratedCopiable, GeneratedFakeable {
    public let dismissedDate: Date?
    public let remindAfter: Date?

    public init(dismissedDate: Date?,
                remindAfter: Date?) {
        self.dismissedDate = dismissedDate
        self.remindAfter = remindAfter
    }
}
