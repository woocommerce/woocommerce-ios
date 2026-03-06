import SwiftUI
import enum Yosemite.BookingAttendanceStatus
import enum Yosemite.BookingPaymentStatus
import enum Yosemite.BookingStatus

struct BookingBadgeView: View {
    let text: String
    let textColor: Color
    let backgroundColor: Color
    let isBordered: Bool

    var body: some View {
        BadgeView(text: text,
                  customizations: .init(
                    textColor: textColor,
                    backgroundColor: backgroundColor,
                    borderColor: isBordered ? BadgeColor.border : nil,
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
    var isBordered: Bool { get }
}

extension BookingBadgeable {
    var isBordered: Bool { false }
}

extension BookingBadgeView {
    init(_ badgeable: BookingBadgeable) {
        self.init(text: badgeable.text,
                  textColor: badgeable.textColor,
                  backgroundColor: badgeable.badgeColor,
                  isBordered: badgeable.isBordered)
    }
}

extension BookingAttendanceStatus: BookingBadgeable {
    var badgeColor: Color {
        switch self {
        case .attended:
            return .clear
        case .unattended, .unknown:
            return BadgeColor.default
        }
    }

    var text: String {
        self.localizedTitle
    }

    var textColor: Color {
        BadgeColor.defaultText
    }

    var isBordered: Bool {
        self == .attended
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

    var textColor: Color {
        BadgeColor.defaultText
    }
}

extension BookingPaymentStatus: BookingBadgeable {
    var badgeColor: Color {
        switch self {
        case .paid, .refunded, .partiallyRefunded:
            return .clear
        case .unpaid, .failed:
            return BadgeColor.info
        }
    }

    var text: String {
        switch self {
        case .paid:
            return Localization.paid
        case .unpaid:
            return Localization.unpaid
        case .failed:
            return Localization.failed
        case .refunded:
            return Localization.refunded
        case .partiallyRefunded:
            return Localization.partiallyRefunded
        }
    }

    var textColor: Color {
        BadgeColor.defaultText
    }

    var isBordered: Bool {
        switch self {
        case .paid, .refunded, .partiallyRefunded:
            return true
        case .unpaid, .failed:
            return false
        }
    }

    private enum Localization {
        static let paid = NSLocalizedString(
            "bookingPaymentStatus.paid",
            value: "Paid",
            comment: "Badge label for a paid booking in the Store Management booking list."
        )
        static let unpaid = NSLocalizedString(
            "bookingPaymentStatus.unpaid",
            value: "Unpaid",
            comment: "Badge label for an unpaid booking in the Store Management booking list."
        )
        static let failed = NSLocalizedString(
            "bookingPaymentStatus.failed",
            value: "Failed",
            comment: "Badge label for a booking with a failed payment."
        )
        static let refunded = NSLocalizedString(
            "bookingPaymentStatus.refunded",
            value: "Refunded",
            comment: "Badge label for a refunded booking."
        )
        static let partiallyRefunded = NSLocalizedString(
            "bookingPaymentStatus.partiallyRefunded",
            value: "Partially Refunded",
            comment: "Badge label for a partially refunded booking."
        )
    }
}

fileprivate enum BadgeColor {
    static let `default` = Color(uiColor: .systemGray6)
    static let info = try! Color(rgbString: "rgba(255, 227, 101, 1)")
    static let defaultText = Color(uiColor: .label)
    static let border = Color(uiColor: .systemGray5)
}
