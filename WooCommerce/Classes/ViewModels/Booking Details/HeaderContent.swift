import Foundation
import struct Networking.Booking

extension BookingDetailsViewModel {
    final class HeaderContent: ObservableObject {
        let bookingDate: String
        let status: [Status]

        @Published var serviceAndCustomerLine: String

        init(_ booking: Booking, customerName: String? = nil) {
            bookingDate = booking.startDate.formatted(
                date: .numeric,
                time: .shortened
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
        func update(customerName: String?) {
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
        }
    }
}

private extension BookingDetailsViewModel {
    enum Constants {
        static let dotSeparator: String = " • "
    }
}
