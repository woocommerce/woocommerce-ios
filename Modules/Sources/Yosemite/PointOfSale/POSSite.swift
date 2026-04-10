// periphery:ignore:all
import Codegen
import Foundation

public struct POSSite: Equatable, GeneratedCopiable, GeneratedFakeable {
    public let siteID: Int64
    public let lastIncrementalSyncDate: Date?
    public let lastFullSyncDate: Date?

    public init(siteID: Int64, lastIncrementalSyncDate: Date? = nil, lastFullSyncDate: Date? = nil) {
        self.siteID = siteID
        self.lastIncrementalSyncDate = lastIncrementalSyncDate
        self.lastFullSyncDate = lastFullSyncDate
    }
}
