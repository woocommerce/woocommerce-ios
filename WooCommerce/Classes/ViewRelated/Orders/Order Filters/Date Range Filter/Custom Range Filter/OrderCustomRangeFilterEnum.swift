import Foundation

/// Represents the start and end dates of a Order Custom Range filter in enum form
///
enum OrderCustomRangeFilterEnum: Hashable {
    case start
    case end
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

    var isActive: Bool {
        return true
    }
}
