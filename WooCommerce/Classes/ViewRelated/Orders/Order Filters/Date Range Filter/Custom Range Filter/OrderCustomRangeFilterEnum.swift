import Foundation

/// Represents the start and end dates of a Order Custom Range filter in enum form
///
enum OrderCustomRangeFilterEnum: Hashable {
    case start(Date?)
    case end(Date?)
}

// MARK: - FilterType conformance
extension OrderCustomRangeFilterEnum: FilterType {
    /// Returns the localized text version of the Enum
    ///
    public var description: String {
        switch self {
        case .start:
            return NSLocalizedString("Start Date", comment: "Label for one of the filters in order custom date range")
        case .end:
            return NSLocalizedString("End Date", comment: "Label for one of the filters in order custom date range")
        }
    }

    /// Returns the current Enum value
    ///
    public var value: Date? {
        switch self {
        case .start(let date):
            return date
        case .end(let date):
            return date
        }
    }

    var isActive: Bool {
        return true
    }
}
