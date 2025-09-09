import Codegen
import Foundation

public struct POSSite: Equatable, GeneratedCopiable, GeneratedFakeable {
    public let siteID: Int64
    public let lastIncrementalSyncDate: Date?

    public init(siteID: Int64, lastIncrementalSyncDate: Date? = nil) {
        self.siteID = siteID
        self.lastIncrementalSyncDate = lastIncrementalSyncDate
    }
}
