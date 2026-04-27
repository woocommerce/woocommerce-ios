import Foundation

public struct POSCoupon: Equatable, Hashable {
    public let id: POSItemIdentifier
    public let code: String
    public let summary: String
    public var dateExpires: Date?

    public init(id: POSItemIdentifier, code: String, summary: String = "", dateExpires: Date? = nil) {
        self.id = id
        self.code = code
        self.summary = summary
        self.dateExpires = dateExpires
    }

    public var isExpired: Bool {
        guard let dateExpires else {
            return false
        }
        return dateExpires <= Date()
    }
}
