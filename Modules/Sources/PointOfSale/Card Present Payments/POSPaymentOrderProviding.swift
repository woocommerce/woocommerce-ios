import struct Yosemite.Order

/// Provides an Order for the payment controller to collect payment against.
/// Cart flow returns the already-synced order; bookings flow fetches by order ID.
protocol POSPaymentOrderProviding {
    func provideOrder() async throws -> Order
}
