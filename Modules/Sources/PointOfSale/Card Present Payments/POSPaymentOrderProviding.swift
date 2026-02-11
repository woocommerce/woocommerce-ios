import struct Yosemite.Order

/// Provides an Order for the payment model to collect payment against.
protocol POSPaymentOrderProviding {
    func provideOrder() async throws -> Order
}
