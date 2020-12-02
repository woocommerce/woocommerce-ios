import UIKit

/// Represents each iOS system color.
enum SystemColor {
    case label
    case secondaryLabel
    case tertiaryLabel
    case quaternaryLabel
    case systemFill
    case secondarySystemFill
    case tertiarySystemFill
    case quaternarySystemFill
    case placeholderText
    case systemBackground
    case secondarySystemBackground
    case tertiarySystemBackground
    case systemGroupedBackground
    case secondarySystemGroupedBackground
    case tertiarySystemGroupedBackground
    case separator
    case opaqueSeparator
    case link
    case darkText
    case lightText
    case systemBlue
    case systemGreen
    case systemIndigo
    case systemOrange
    case systemPink
    case systemPurple
    case systemRed
    case systemTeal
    case systemYellow
    case systemGray
    case systemGray2
    case systemGray3
    case systemGray4
    case systemGray5
    case systemGray6
}

private extension SystemColor {
    var color: UIColor {
        switch self {
        case .label: return .label
        case .secondaryLabel: return .secondaryLabel
        case .tertiaryLabel: return .tertiaryLabel
        case .quaternaryLabel: return .quaternaryLabel
        case .systemFill: return .systemFill
        case .secondarySystemFill: return .secondarySystemFill
        case .tertiarySystemFill: return .tertiarySystemFill
        case .quaternarySystemFill: return .quaternarySystemFill
        case .placeholderText: return .placeholderText
        case .systemBackground: return .systemBackground
        case .secondarySystemBackground: return .secondarySystemBackground
        case .tertiarySystemBackground: return .tertiarySystemBackground
        case .systemGroupedBackground: return .systemGroupedBackground
        case .secondarySystemGroupedBackground: return .secondarySystemGroupedBackground
        case .tertiarySystemGroupedBackground: return .tertiarySystemGroupedBackground
        case .separator: return .separator
        case .opaqueSeparator: return .opaqueSeparator
        case .link: return .textLink
        case .darkText: return .darkText
        case .lightText: return .lightText
        case .systemBlue: return .systemBlue
        case .systemGreen: return .systemGreen
        case .systemIndigo: return .systemIndigo
        case .systemOrange: return .systemOrange
        case .systemPink: return .systemPink
        case .systemPurple: return .systemPurple
        case .systemRed: return .systemRed
        case .systemTeal: return .systemTeal
        case .systemYellow: return .systemYellow
        case .systemGray: return .systemGray
        case .systemGray2: return .systemGray2
        case .systemGray3: return .systemGray3
        case .systemGray4: return .systemGray4
        case .systemGray5: return .systemGray5
        case .systemGray6: return .systemGray6
        }
    }
}

extension UIColor {

    /// Get a system color.
    ///
    /// - Parameters:
    ///   - systemColor: a system color enum
    /// - Returns: UIColor for each system color
    class func systemColor(_ systemColor: SystemColor) -> UIColor {
        return systemColor.color
    }
}
