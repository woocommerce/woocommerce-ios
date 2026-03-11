import SwiftUI
import enum Yosemite.BookingAttendanceStatus
import enum Yosemite.BookingPaymentStatus
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
        BadgeColor.default
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

extension BookingPaymentStatus: BookingBadgeable {
    var badgeColor: Color {
        BadgeColor.default
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
        case .authorized:
            return Localization.authorized
        case .authorizationVoided:
            return Localization.authorizationVoided
        }
    }

    var textColor: Color {
        BadgeColor.defaultText
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
        static let authorized = NSLocalizedString(
            "bookingPaymentStatus.authorized",
            value: "Authorized",
            comment: "Badge label for a booking with an authorized but not yet captured payment."
        )
        static let authorizationVoided = NSLocalizedString(
            "bookingPaymentStatus.authorizationVoided",
            value: "Authorization Voided",
            comment: "Badge label for a booking where the payment authorization has been voided."
        )
    }
}

fileprivate enum BadgeColor {
    static let `default` = Color(uiColor: .systemGray6.resolvedColor(with: .init(userInterfaceStyle: .light)))
    static let info = try! Color(rgbString: "rgba(255, 227, 101, 1)")
    static let cancelledBackground = try! Color(rgbString: "rgba(225, 236, 248, 1)")
    static let cancelledText = try! Color(rgbString: "rgba(0, 23, 88, 1)")
    static let defaultText = Color(UIColor.label.resolvedColor(with: .init(userInterfaceStyle: .light)))
}
