import Foundation

/// Various sizes of error and alert icons in POS.
/// Design ref: 1qcjzXitBHU7xPnpCOWnNM-fi-1114_19201
enum POSErrorAndAlertIconSize {
    case small
    case medium
    case large

    var dimension: CGFloat {
        switch self {
        case .small:
            return 40.0
        case .medium:
            return 56.0
        case .large:
            return 80.0
        }
    }
}
