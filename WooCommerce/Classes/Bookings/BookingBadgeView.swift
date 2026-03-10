import SwiftUI
import enum Yosemite.BookingAttendanceStatus
import enum Yosemite.BookingPaymentStatus
import enum Yosemite.BookingStatus

struct BookingBadgeView: View {
    let text: String
    let textColor: Color
    let backgroundColor: Color
    let borderColor: Color?

    var body: some View {
        BadgeView(text: text,
                  customizations: .init(
                    textColor: textColor,
                    backgroundColor: backgroundColor,
                    borderColor: borderColor,
                    bold: false
                  ),
                  backgroundShape: .roundedRectangle(cornerRadius: Layout.cornerRadius))
    }
}

// MARK: - Badge Styles

extension BookingBadgeView {
static func `default`(text: String) -> BookingBadgeView {
        BookingBadgeView(text: text,
                         textColor: BadgeStyle.lightText,
                         backgroundColor: BadgeStyle.defaultBackground,
                         borderColor: BadgeStyle.border)
    }

static func info(text: String) -> BookingBadgeView {
        BookingBadgeView(text: text,
                         textColor: BadgeStyle.cancelledText,
                         backgroundColor: BadgeStyle.cancelled,
                         borderColor: nil)
    }

static func warning(text: String) -> BookingBadgeView {
        BookingBadgeView(text: text,
                         textColor: BadgeStyle.lightText,
                         backgroundColor: BadgeStyle.warning,
                         borderColor: nil)
    }

static func muted(text: String) -> BookingBadgeView {
        BookingBadgeView(text: text,
                         textColor: BadgeStyle.lightText,
                         backgroundColor: BadgeStyle.muted,
                         borderColor: nil)
    }
}

// MARK: - BookingBadgeable

protocol BookingBadgeable {
    var bookingBadge: BookingBadgeView { get }
}

extension BookingBadgeView {
    init(_ badgeable: BookingBadgeable) {
        self = badgeable.bookingBadge
    }
}

// MARK: - BookingAttendanceStatus

extension BookingAttendanceStatus: BookingBadgeable {
    var bookingBadge: BookingBadgeView {
        switch self {
        case .attended:
            return .default(text: localizedTitle)
        case .unattended, .unknown:
            return .muted(text: localizedTitle)
        }
    }
}

// MARK: - BookingStatus

extension BookingStatus: BookingBadgeable {
    var bookingBadge: BookingBadgeView {
        switch self {
        case .cancelled:
            return .info(text: localizedTitle)
        default:
            return .default(text: localizedTitle)
        }
    }
}

// MARK: - BookingPaymentStatus

extension BookingPaymentStatus: BookingBadgeable {
    var bookingBadge: BookingBadgeView {
        switch self {
        case .paid, .refunded, .partiallyRefunded:
            return .default(text: text)
        case .unpaid, .failed:
            return .warning(text: text)
        }
    }

    private var text: String {
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

// MARK: - Layout & Colors

private extension BookingBadgeView {
    enum Layout {
        static let cornerRadius: CGFloat = 4
    }
}

private enum BadgeStyle {
    static let lightGray6 = UIColor.systemGray6.resolvedColor(with: .init(userInterfaceStyle: .light))

static let defaultBackground = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark ? lightGray6 : .clear
    })
    static let muted = Color(uiColor: lightGray6)
    static let cancelled = Color(UIColor(red: 225/255, green: 236/255, blue: 248/255, alpha: 1))
    static let cancelledText = Color(UIColor(red: 0/255, green: 23/255, blue: 88/255, alpha: 1))
    static let warning = try! Color(rgbString: "rgba(255, 227, 101, 1)")
    static let lightText = Color(UIColor.label.resolvedColor(with: .init(userInterfaceStyle: .light)))
    static let border = Color(uiColor: .systemGray5)
}
