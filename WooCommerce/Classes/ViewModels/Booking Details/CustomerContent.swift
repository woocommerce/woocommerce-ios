import Foundation
import Networking

extension BookingDetailsViewModel {
    final class CustomerContent: ObservableObject {
        @Published var nameText: String?
        @Published var emailText: String?
        @Published var phoneText: String?
        @Published var billingAddressText: String?

        @MainActor
        func update(with address: Address) {
            let name = [
                address.firstName,
                address.lastName
            ]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: " ")

            let billingAddress = formatAddress(address)

            nameText = name
            emailText = address.email
            phoneText = address.phone ?? ""
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
