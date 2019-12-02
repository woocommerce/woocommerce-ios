import UIKit
import Gridicons
import Aztec

protocol FormatBarItemViewProperties {
    var iconImage: UIImage { get }
    var accessibilityLabel: String { get }
    var accessibilityHint: String { get }
}

// MARK: - FormattingIdentifier
//
extension FormattingIdentifier: FormatBarItemViewProperties {
    var iconImage: UIImage {
        switch self {
        case .media:
            return Gridicon.iconOfType(.addOutline)
        case .p:
            return Gridicon.iconOfType(.heading)
        case .bold:
            return Gridicon.iconOfType(.bold)
        case .italic:
            return Gridicon.iconOfType(.italic)
        case .underline:
            return Gridicon.iconOfType(.underline)
        case .strikethrough:
            return Gridicon.iconOfType(.strikethrough)
        case .blockquote:
            return Gridicon.iconOfType(.quote)
        case .orderedlist:
            if layoutDirection == .leftToRight {
                return Gridicon.iconOfType(.listOrdered)
            } else {
                return Gridicon.iconOfType(.listOrderedRTL)
            }
        case .unorderedlist:
            return Gridicon.iconOfType(.listUnordered).imageFlippedForRightToLeftLayoutDirection()
        case .link:
            return Gridicon.iconOfType(.link)
        case .horizontalruler:
            return Gridicon.iconOfType(.minusSmall)
        case .sourcecode:
            return Gridicon.iconOfType(.code)
        case .more:
            return Gridicon.iconOfType(.readMore)
        case .header1:
            return Gridicon.iconOfType(.headingH1)
        case .header2:
            return Gridicon.iconOfType(.headingH2)
        case .header3:
            return Gridicon.iconOfType(.headingH3)
        case .header4:
            return Gridicon.iconOfType(.headingH4)
        case .header5:
            return Gridicon.iconOfType(.headingH5)
        case .header6:
            return Gridicon.iconOfType(.headingH6)
        default:
            return Gridicon.iconOfType(.help)
        }
    }

    private var layoutDirection: UIUserInterfaceLayoutDirection {
        return UIView.userInterfaceLayoutDirection(for: .unspecified)
    }

    var accessibilityLabel: String {
        switch self {
        case .p:
            return NSLocalizedString("Select paragraph style", comment: "Accessibility label for selecting paragraph style button on formatting toolbar.")
        case .bold:
            return NSLocalizedString("Bold", comment: "Accessibility label for bold button on formatting toolbar.")
        case .italic:
            return NSLocalizedString("Italic", comment: "Accessibility label for italic button on formatting toolbar.")
        case .underline:
            return NSLocalizedString("Underline", comment: "Accessibility label for underline button on formatting toolbar.")
        case .strikethrough:
            return NSLocalizedString("Strike Through", comment: "Accessibility label for strikethrough button on formatting toolbar.")
        case .blockquote:
            return NSLocalizedString("Block Quote", comment: "Accessibility label for block quote button on formatting toolbar.")
        case .orderedlist:
            return NSLocalizedString("Ordered List", comment: "Accessibility label for Ordered list button on formatting toolbar.")
        case .unorderedlist:
            return NSLocalizedString("Unordered List", comment: "Accessibility label for unordered list button on formatting toolbar.")
        case .link:
            return NSLocalizedString("Insert Link", comment: "Accessibility label for insert link button on formatting toolbar.")
        case .horizontalruler:
            return NSLocalizedString("Insert Horizontal Ruler", comment: "Accessibility label for insert horizontal ruler button on formatting toolbar.")
        case .sourcecode:
            return NSLocalizedString("HTML", comment: "Accessibility label for HTML button on formatting toolbar.")
        case .more:
            return NSLocalizedString("More", comment: "Accessibility label for the More button on formatting toolbar.")
        case .header1:
            return NSLocalizedString("Header 1", comment: "Accessibility label for selecting h1 paragraph style button on the formatting toolbar.")
        case .header2:
            return NSLocalizedString("Header 2", comment: "Accessibility label for selecting h2 paragraph style button on the formatting toolbar.")
        case .header3:
            return NSLocalizedString("Header 3", comment: "Accessibility label for selecting h3 paragraph style button on the formatting toolbar.")
        case .header4:
            return NSLocalizedString("Header 4", comment: "Accessibility label for selecting h4 paragraph style button on the formatting toolbar.")
        case .header5:
            return NSLocalizedString("Header 5", comment: "Accessibility label for selecting h5 paragraph style button on the formatting toolbar.")
        case .header6:
            return NSLocalizedString("Header 6", comment: "Accessibility label for selecting h6 paragraph style button on the formatting toolbar.")
        default:
            return ""
        }
    }

    var accessibilityHint: String {
        switch self {
        case .p:
            return NSLocalizedString("Tap to toggle paragraph style",
                                     comment: "Accessibility hint for selecting paragraph style button on formatting toolbar.")
        case .bold:
            return NSLocalizedString("Tap to toggle Bold text",
                                     comment: "Accessibility hint for bold button on formatting toolbar.")
        case .italic:
            return NSLocalizedString("Tap to toggle Italic text",
                                     comment: "Accessibility hint for italic button on formatting toolbar.")
        case .underline:
            return NSLocalizedString("Tap to toggle Underline",
                                     comment: "Accessibility hint for underline button on formatting toolbar.")
        case .strikethrough:
            return NSLocalizedString("Tap to toggle Strike Through",
                                     comment: "Accessibility hint for strikethrough button on formatting toolbar.")
        case .blockquote:
            return NSLocalizedString("Tap to toggle Block Quote",
                                     comment: "Accessibility hint for block quote button on formatting toolbar.")
        case .orderedlist:
            return NSLocalizedString("Tap to toggle Ordered List",
                                     comment: "Accessibility hint for Ordered list button on formatting toolbar.")
        case .unorderedlist:
            return NSLocalizedString("Tap to toggle Unordered List",
                                     comment: "Accessibility hint for unordered list button on formatting toolbar.")
        case .link:
            return NSLocalizedString("Tap to insert a Link",
                                     comment: "Accessibility hint for insert link button on formatting toolbar.")
        case .horizontalruler:
            return NSLocalizedString("Tap to insert a Horizontal Ruler",
                                     comment: "Accessibility hint for insert horizontal ruler button on formatting toolbar.")
        case .sourcecode:
            return NSLocalizedString("Tap to toggle HTML mode",
                                     comment: "Accessibility hint for HTML button on formatting toolbar.")
        case .more:
            return NSLocalizedString("Tap for more formatting options",
                                     comment: "Accessibility hint for the More button on formatting toolbar.")
        case .header1:
            return NSLocalizedString("Tap to toggle Header 1",
                                     comment: "Accessibility hint for selecting h1 paragraph style button on the formatting toolbar.")
        case .header2:
            return NSLocalizedString("Tap to toggle Header 2",
                                     comment: "Accessibility hint for selecting h2 paragraph style button on the formatting toolbar.")
        case .header3:
            return NSLocalizedString("Tap to toggle Header 3",
                                     comment: "Accessibility hint for selecting h3 paragraph style button on the formatting toolbar.")
        case .header4:
            return NSLocalizedString("Tap to toggle Header 4",
                                     comment: "Accessibility hint for selecting h4 paragraph style button on the formatting toolbar.")
        case .header5:
            return NSLocalizedString("Tap to toggle Header 5",
                                     comment: "Accessibility hint for selecting h5 paragraph style button on the formatting toolbar.")
        case .header6:
            return NSLocalizedString("Tap to toggle Header 6",
                                     comment: "Accessibility hint for selecting h6 paragraph style button on the formatting toolbar.")
        default:
            return ""
        }
    }
}
