import SwiftUI
import enum Yosemite.BookingAttendanceStatus
import enum Yosemite.BookingStatus

struct BookingBadgeView: View {
    let text: String
    let color: Color

    var body: some View {
        BadgeView(text: text,
                  customizations: .init(textColor: Color(UIColor.label.resolvedColor(with: .init(userInterfaceStyle: .light))),
                                        backgroundColor: color,
                                        bordered: false,
                                        bold: false),
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
    var badgeColor: Color { get }
}

extension BookingBadgeView {
    init(_ badgeable: BookingBadgeable) {
        self.init(text: badgeable.text, color: badgeable.badgeColor)
    }
}

extension BookingAttendanceStatus: BookingBadgeable {
    var badgeColor: Color {
        BadgeColor.default
    }

    var text: String {
        self.localizedTitle
    }
}

extension BookingStatus: BookingBadgeable {
    var badgeColor: Color {
        switch self {
        case .unpaid:
            return BadgeColor.info
        default:
            return BadgeColor.default
        }
    }

    var text: String {
        self.localizedTitle
    }
}

fileprivate enum BadgeColor {
    static let `default` = Color(uiColor: .systemGray6.resolvedColor(with: .init(userInterfaceStyle: .light)))
    static let info = try! Color(rgbString: "rgba(255, 227, 101, 1)")
}
