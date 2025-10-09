import Foundation
import struct Yosemite.Booking
import struct Yosemite.Customer

extension BookingDetailsViewModel {
    final class HeaderContent: ObservableObject {
        let bookingDate: String
        let status: [Status]

        @Published var serviceAndCustomerLine: String

        init(_ booking: Booking, customerName: String? = nil) {
            bookingDate = booking.startDate.toString(
                dateStyle: .short,
                timeStyle: .short,
                timeZone: BookingListTab.utcTimeZone
            )

            /// Temporary hardcode for service name
            let serviceName = "Women's Haircut"
            if let customerName = customerName, !customerName.isEmpty {
                serviceAndCustomerLine = [
                    serviceName,
                    customerName
                ].joined(separator: Constants.dotSeparator)
            } else {
                serviceAndCustomerLine = serviceName
            }

            status = [.booked, .payAtLocation]
        }

        @MainActor
        func update(with customer: Customer) {
            let customerName = [
                customer.firstName,
                customer.lastName
            ]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: " ")

            /// Temporary hardcode for service name
            let serviceName = "Women's Haircut"
            if !customerName.isEmpty {
                serviceAndCustomerLine = [
                    serviceName,
                    customerName
                ].joined(separator: Constants.dotSeparator)
            } else {
                serviceAndCustomerLine = serviceName
            }
        }
    }
}

private extension BookingDetailsViewModel {
    enum Constants {
        static let dotSeparator: String = " • "
    }
}
