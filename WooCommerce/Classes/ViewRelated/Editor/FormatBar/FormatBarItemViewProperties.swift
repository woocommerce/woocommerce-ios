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
            return UIImage.gridicon(.addOutline)
        case .p:
            return UIImage.gridicon(.heading)
        case .bold:
            return UIImage.gridicon(.bold)
        case .italic:
            return UIImage.gridicon(.italic)
        case .underline:
            return UIImage.gridicon(.underline)
        case .strikethrough:
            return UIImage.gridicon(.strikethrough)
        case .blockquote:
            return UIImage.gridicon(.quote)
        case .orderedlist:
            if layoutDirection == .leftToRight {
                return UIImage.gridicon(.listOrdered)
            } else {
                return UIImage.gridicon(.listOrderedRtl)
            }
        case .unorderedlist:
            return UIImage.gridicon(.listUnordered).imageFlippedForRightToLeftLayoutDirection()
        case .link:
            return UIImage.gridicon(.link)
        case .horizontalruler:
            return UIImage.gridicon(.minusSmall)
        case .sourcecode:
            return UIImage.gridicon(.code)
        case .more:
            return UIImage.gridicon(.readMore)
        case .header1:
            return UIImage.gridicon(.headingH1)
        case .header2:
            return UIImage.gridicon(.headingH2)
        case .header3:
            return UIImage.gridicon(.headingH3)
        case .header4:
            return UIImage.gridicon(.headingH4)
        case .header5:
            return UIImage.gridicon(.headingH5)
        case .header6:
            return UIImage.gridicon(.headingH6)
        default:
            return UIImage.gridicon(.help)
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
