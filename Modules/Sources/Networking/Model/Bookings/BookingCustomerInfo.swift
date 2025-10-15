import Foundation

public struct BookingCustomerInfo: Hashable {
    public let billingAddress: Address

    public init(billingAddress: Address) {
        self.billingAddress = billingAddress
    }
}
