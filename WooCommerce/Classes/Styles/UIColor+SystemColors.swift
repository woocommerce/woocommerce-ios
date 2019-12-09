import UIKit

/// Represents each iOS system color, available in iOS 13+.
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
        if #available(iOS 13, *) {
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
            case .link: return .link
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

        switch self {
        case .label: // rgba(0.0, 0.0, 0.0, 1.0)
            return .init(red: 0, green: 0, blue: 0, alpha: 1)
        case .secondaryLabel: // #3c3c4399    rgba(60.0, 60.0, 67.0, 0.6)
            return .init(red: 60/255.0, green: 60/255.0, blue: 67/255.0, alpha: 1)
        case .tertiaryLabel: // #3c3c434c    rgba(60.0, 60.0, 67.0, 0.3)
            return .init(red: 60/255.0, green: 60/255.0, blue: 67/255.0, alpha: 0.3)
        case .quaternaryLabel: // #3c3c432d    rgba(60.0, 60.0, 67.0, 0.18)
            return .init(red: 60/255.0, green: 60/255.0, blue: 67/255.0, alpha: 0.18)
        case .systemFill: // #78788033    rgba(120.0, 120.0, 128.0, 0.2)
            return .init(red: 120/255.0, green: 120/255.0, blue: 128/255.0, alpha: 0.2)
        case .secondarySystemFill: // #78788028    rgba(120.0, 120.0, 128.0, 0.16)
            return .init(red: 120/255.0, green: 120/255.0, blue: 128/255.0, alpha: 0.16)
        case .tertiarySystemFill: // #7676801e    rgba(118.0, 118.0, 128.0, 0.12)
            return .init(red: 118/255.0, green: 118/255.0, blue: 128/255.0, alpha: 0.12)
        case .quaternarySystemFill: // #74748014    rgba(116.0, 116.0, 128.0, 0.08)
            return .init(red: 116/255.0, green: 116/255.0, blue: 128/255.0, alpha: 0.08)
        case .placeholderText: // #3c3c434c    rgba(60.0, 60.0, 67.0, 0.3)
            return .init(red: 60/255.0, green: 60/255.0, blue: 67/255.0, alpha: 0.3)
        case .systemBackground: // #ffffffff    rgba(255.0, 255.0, 255.0, 1.0)
            return .init(red: 255/255.0, green: 255/255.0, blue: 255/255.0, alpha: 1)
        case .secondarySystemBackground: // #f2f2f7ff    rgba(242.0, 242.0, 247.0, 1.0)
            return .init(red: 242/255.0, green: 242/255.0, blue: 247/255.0, alpha: 1)
        case .tertiarySystemBackground: // #ffffffff    rgba(255.0, 255.0, 255.0, 1.0)
            return .init(red: 255/255.0, green: 255/255.0, blue: 255/255.0, alpha: 1)
        case .systemGroupedBackground: // #f2f2f7ff    rgba(242.0, 242.0, 247.0, 1.0)
            return .init(red: 242/255.0, green: 242/255.0, blue: 247/255.0, alpha: 1)
        case .secondarySystemGroupedBackground: // #ffffffff    rgba(255.0, 255.0, 255.0, 1.0)
            return .init(red: 255/255.0, green: 255/255.0, blue: 255/255.0, alpha: 1)
        case .tertiarySystemGroupedBackground: // #f2f2f7ff    rgba(242.0, 242.0, 247.0, 1.0)
            return .init(red: 242/255.0, green: 242/255.0, blue: 247/255.0, alpha: 1)
        case .separator: // #3c3c4349    rgba(60.0, 60.0, 67.0, 0.29)
            return .init(red: 60/255.0, green: 60/255.0, blue: 67/255.0, alpha: 0.29)
        case .opaqueSeparator: // #c6c6c8ff    rgba(198.0, 198.0, 200.0, 1.0)
            return .init(red: 198/255.0, green: 198/255.0, blue: 200/255.0, alpha: 1)
        case .link: // #007affff    rgba(0.0, 122.0, 255.0, 1.0)
            return .init(red: 0/255.0, green: 122/255.0, blue: 255/255.0, alpha: 1)
        case .darkText: // #000000ff    rgba(0.0, 0.0, 0.0, 1.0)
            return .init(red: 0/255.0, green: 0/255.0, blue: 0/255.0, alpha: 1)
        case .lightText: // #ffffff99    rgba(255.0, 255.0, 255.0, 0.6)
            return .init(red: 255/255.0, green: 255/255.0, blue: 255/255.0, alpha: 0.6)
        case .systemBlue: // #007affff    rgba(0.0, 122.0, 255.0, 1.0)
            return .init(red: 0/255.0, green: 122/255.0, blue: 255/255.0, alpha: 1)
        case .systemGreen: // #34c759ff    rgba(52.0, 199.0, 89.0, 1.0)
            return .init(red: 52/255.0, green: 199/255.0, blue: 89/255.0, alpha: 1)
        case .systemIndigo: // #5856d6ff    rgba(88.0, 86.0, 214.0, 1.0)
            return .init(red: 88/255.0, green: 86/255.0, blue: 214/255.0, alpha: 1)
        case .systemOrange: // #ff9500ff    rgba(255.0, 149.0, 0.0, 1.0)
            return .init(red: 255/255.0, green: 149/255.0, blue: 0/255.0, alpha: 1)
        case .systemPink: // #ff2d55ff    rgba(255.0, 45.0, 85.0, 1.0)
            return .init(red: 255/255.0, green: 45/255.0, blue: 85/255.0, alpha: 1)
        case .systemPurple: // #af52deff    rgba(175.0, 82.0, 222.0, 1.0)
            return .init(red: 175/255.0, green: 82/255.0, blue: 222/255.0, alpha: 1)
        case .systemRed: // #ff3b30ff    rgba(255.0, 59.0, 48.0, 1.0)
            return .init(red: 255/255.0, green: 59/255.0, blue: 48/255.0, alpha: 1)
        case .systemTeal: // #5ac8faff    rgba(90.0, 200.0, 250.0, 1.0)
            return .init(red: 90/255.0, green: 200/255.0, blue: 250/255.0, alpha: 1)
        case .systemYellow: // #ffcc00ff    rgba(255.0, 204.0, 0.0, 1.0)
            return .init(red: 255/255.0, green: 204/255.0, blue: 0/255.0, alpha: 1)
        case .systemGray: // #8e8e93ff    rgba(142.0, 142.0, 147.0, 1.0)
            return .init(red: 142/255.0, green: 142/255.0, blue: 147/255.0, alpha: 1)
        case .systemGray2: // #aeaeb2ff    rgba(174.0, 174.0, 178.0, 1.0)
            return .init(red: 174/255.0, green: 174/255.0, blue: 178/255.0, alpha: 1)
        case .systemGray3: // #c7c7ccff    rgba(199.0, 199.0, 204.0, 1.0)
            return .init(red: 199/255.0, green: 199/255.0, blue: 204/255.0, alpha: 1)
        case .systemGray4: // #d1d1d6ff    rgba(209.0, 209.0, 214.0, 1.0)
            return .init(red: 209/255.0, green: 209/255.0, blue: 214/255.0, alpha: 1)
        case .systemGray5: // #e5e5eaff    rgba(229.0, 229.0, 234.0, 1.0)
            return .init(red: 229/255.0, green: 229/255.0, blue: 234/255.0, alpha: 1)
        case .systemGray6: // #f2f2f7ff    rgba(242.0, 242.0, 247.0, 1.0)
            return .init(red: 242/255.0, green: 242/255.0, blue: 247/255.0, alpha: 1)
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
