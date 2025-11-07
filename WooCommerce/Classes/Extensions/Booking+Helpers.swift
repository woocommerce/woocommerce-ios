import Foundation
import struct Yosemite.Booking

extension Booking {
    var productName: String? {
        orderInfo?.productInfo?.name
    }

    var customerName: String {
        guard let name = orderInfo?.customerInfo?.billingAddress.fullName else {
            return Localization.guest
        }
        return name.isEmpty ? Localization.guest : name
    }

    var summaryText: String {
        return [productName, customerName]
            .compactMap { $0 }
            .joined(separator: "  •  ")
    }

    private enum Localization {
        static let guest = NSLocalizedString(
            "bookings.guest",
            value: "Guest",
            comment: "Displayed name on the booking list when no customer is associated with a booking."
        )
    }
}
