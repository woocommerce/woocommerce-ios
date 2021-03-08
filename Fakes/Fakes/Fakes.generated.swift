// Generated using Sourcery 1.0.3 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT
import Networking

extension OrderItemTax {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> OrderItemTax {
        OrderItemTax(
            taxID: .fake(),
            subtotal: .fake(),
            total: .fake()
        )
    }
}

