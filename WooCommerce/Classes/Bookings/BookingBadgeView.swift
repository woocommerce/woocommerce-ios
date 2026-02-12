import SwiftUI
import enum Yosemite.BookingAttendanceStatus
import enum Yosemite.BookingStatus

struct BookingBadgeView: View {
    let text: String
    let textColor: Color
    let color: Color

    var body: some View {
        BadgeView(text: text,
                  customizations: .init(
                    textColor: textColor,
                    backgroundColor: color,
                    bordered: false,
                    bold: false
                  ),
                  backgroundShape: .roundedRectangle(cornerRadius: Layout.cornerRadius))
    }
}

private extension BookingBadgeView {
    enum Layout {
        static let cornerRadius: CGFloat = 4
    }
}

protocol BookingBadgeable {
    var text: String { get }
    var textColor: Color { get }
    var badgeColor: Color { get }
}

extension BookingBadgeView {
    init(_ badgeable: BookingBadgeable) {
        self.init(text: badgeable.text, textColor: badgeable.textColor, color: badgeable.badgeColor)
    }
}

extension BookingAttendanceStatus: BookingBadgeable {
    var badgeColor: Color {
        switch self {
        case .noShow:
            return BadgeColor.info
        default:
            return BadgeColor.default
        }
    }

    var text: String {
        self.localizedTitle
    }

    var textColor: Color {
        BadgeColor.defaultText
    }
}

extension BookingStatus: BookingBadgeable {
    var badgeColor: Color {
        switch self {
        case .cancelled:
            return BadgeColor.cancelledBackground
        case .unpaid:
            return BadgeColor.info
        default:
            return BadgeColor.default
        }
    }

    var text: String {
        self.localizedTitle
    }

    var textColor: Color {
        switch self {
        case .cancelled:
            return BadgeColor.cancelledText
        default:
            return BadgeColor.defaultText
        }
    }
}

fileprivate enum BadgeColor {
    static let `default` = Color(uiColor: .systemGray6.resolvedColor(with: .init(userInterfaceStyle: .light)))
    static let info = try! Color(rgbString: "rgba(255, 227, 101, 1)")
    static let cancelledBackground = try! Color(rgbString: "rgba(225, 236, 248, 1)")
    static let cancelledText = try! Color(rgbString: "rgba(0, 23, 88, 1)")
    static let defaultText = Color(UIColor.label.resolvedColor(with: .init(userInterfaceStyle: .light)))
}
