import Foundation

public struct BookingCustomerInfo: Hashable, Sendable {
    public let billingAddress: Address
    public let note: String?

    public init(billingAddress: Address, note: String? = nil) {
        self.billingAddress = billingAddress
        self.note = note
    }
}
