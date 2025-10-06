import Foundation
import Networking

extension BookingDetailsViewModel {
    final class CustomerContent: ObservableObject {
        @Published var nameText: String?
        @Published var emailText: String?
        @Published var phoneText: String?
        @Published var billingAddressText: String?

        func update(with customer: Customer) {
            let name = [
                customer.firstName,
                customer.lastName
            ]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: " ")

            let billingAddress = customer.billing.flatMap(formatAddress)

            nameText = name
            emailText = customer.email
            phoneText = customer.billing?.phone ?? ""
            billingAddressText = billingAddress
        }

        private func formatAddress(_ address: Address) -> String {
            [
                address.address1,
                address.address2,
                address.city,
                address.state,
                address.postcode,
                address.country
            ]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: "\n")
        }
    }
}
