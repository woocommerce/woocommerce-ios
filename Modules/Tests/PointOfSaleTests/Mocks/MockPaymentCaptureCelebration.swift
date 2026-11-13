@testable import PointOfSale
import protocol Yosemite.PaymentCaptureCelebrationProtocol

final class MockPaymentCaptureCelebration: PaymentCaptureCelebrationProtocol {
    private(set) var celebrationWasCalled: Bool = false
    /// `playsSound` passed to the last celebration, `nil` before any.
    private(set) var playedSound: Bool?

    func celebrate(playsSound: Bool) {
        celebrationWasCalled = true
        playedSound = playsSound
    }
}
