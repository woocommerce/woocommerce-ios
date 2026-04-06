import Foundation
import enum Yosemite.POSItem
import struct Yosemite.POSBooking
import PointOfSale

struct MockConfiguration {
    var products: [POSItem] = []
    var productLoadDelay: TimeInterval = 0.3
    var paymentSequence: PaymentSequence = .successAfterDelay(2.0)
    var initialReaderConnectionStatus: CardPresentPaymentReaderConnectionStatus = .disconnected
    var shouldShowOnboarding: Bool = false
    var orderSyncDelay: TimeInterval = 0.5
    var orderSyncShouldFail: Bool = false
    var taxRate: Decimal = 0.08
    var storeName: String = "Prototype Store"
    var currencyCode: String = "USD"
    var bookings: [POSBooking] = []
    var isBookingsEligible: Bool = false
}
