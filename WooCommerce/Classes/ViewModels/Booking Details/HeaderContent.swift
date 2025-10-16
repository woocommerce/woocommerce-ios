import Foundation
import struct Yosemite.Booking
import struct Yosemite.BookingProductInfo
import struct Yosemite.Customer
import struct Yosemite.Address

extension BookingDetailsViewModel {
    final class HeaderContent: ObservableObject {
        @Published var bookingDate: String = ""
        @Published var status: [Status] = []
        @Published var serviceAndCustomerLine: String = ""

        init(_ booking: Booking) {
            update(with: booking)
        }

        func update(with booking: Booking) {
            bookingDate = booking.startDate.toString(
                dateStyle: .short,
                timeStyle: .short,
                timeZone: BookingListTab.utcTimeZone
            )

            let serviceName = booking.orderInfo?.productInfo?.name ?? ""
            let customerName = [
                booking.orderInfo?.customerInfo?.billingAddress.firstName,
                booking.orderInfo?.customerInfo?.billingAddress.lastName
            ]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: " ")

            if !customerName.isEmpty {
                serviceAndCustomerLine = [
                    serviceName,
                    customerName
                ].joined(separator: Constants.dotSeparator)
            } else {
                serviceAndCustomerLine = serviceName
            }

            status = [.booked, .payAtLocation]
        }
    }
}

private extension BookingDetailsViewModel {
    enum Constants {
        static let dotSeparator: String = " • "
    }
}
