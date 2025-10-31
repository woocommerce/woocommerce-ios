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
                                        bold: false))
    }
}

extension BookingBadgeView {
    init(_ status: BookingAttendanceStatus) {
        self.init(text: status.localizedTitle, color: status.badgeColor)
    }

    init(_ status: BookingStatus) {
        self.init(text: status.localizedTitle, color: status.badgeColor)
    }
}

extension BookingAttendanceStatus {
    var badgeColor: Color {
        switch self {
        case .noShow:
            return BadgeColor.info
        default:
            return BadgeColor.default
        }
    }
}

extension BookingStatus {
    var badgeColor: Color {
        switch self {
        case .unpaid:
            return BadgeColor.info
        default:
            return BadgeColor.default
        }
    }
}

fileprivate enum BadgeColor {
    static let `default` = Color(uiColor: .systemGray6.resolvedColor(with: .init(userInterfaceStyle: .light)))
    static let info = try! Color(rgbString: "rgba(255, 227, 101, 1)")
}
