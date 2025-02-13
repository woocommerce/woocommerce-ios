import Foundation

/// Defines the corner radius styles used in POS.
/// Each case represents a different size of corner radius.
/// Design ref: 1qcjzXitBHU7xPnpCOWnNM-fi-21_7275
enum POSCornerRadiusStyle {
    case extraSmall
    case small
    case medium
    case large
    case extraLarge
    case full

    var value: CGFloat {
        switch self {
        case .extraSmall:
            return 2
        case .small:
            return 4
        case .medium:
            return 8
        case .large:
            return 16
        case .extraLarge:
            return 24
        case .full:
            return 200
        }
    }
}
