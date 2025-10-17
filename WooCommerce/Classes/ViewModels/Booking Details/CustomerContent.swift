import Foundation
import Networking

extension BookingDetailsViewModel {
    final class CustomerContent: ObservableObject {
        @Published var nameText: String?
        @Published var emailText: String?
        @Published var phoneText: String?
        @Published var billingAddressText: String?

        init(billingAddress: Address) {
            nameText = billingAddress.fullName
            emailText = billingAddress.email ?? ""
            phoneText = billingAddress.phone ?? ""
            billingAddressText = formatAddress(billingAddress)
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
