import Foundation

/// Various sizes of error and alert icons in POS.
/// Design ref: 1qcjzXitBHU7xPnpCOWnNM-fi-1114_19201
enum POSErrorAndAlertIconSize {
    case small
    case medium
    case large
    /// Large icon reduced to make room for the keyboard in POS status screens.
    case largeCompact

    var dimension: CGFloat {
        switch self {
        case .small:
            return 40.0
        case .medium:
            return 56.0
        case .large:
            return 80.0
        case .largeCompact:
            return 60.0
        }
    }
}
