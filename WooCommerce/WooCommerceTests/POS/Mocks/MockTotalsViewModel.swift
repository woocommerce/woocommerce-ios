import Combine
import Foundation
@testable import WooCommerce
import protocol Yosemite.POSItem
import struct Yosemite.Order

final class MockTotalsViewModel: TotalsViewModelProtocol {
    func startNewOrder() { }

    var spyStopShowingTotalsViewCalled = false
    func stopShowingTotalsView() {
        spyStopShowingTotalsViewCalled = true
    }

    var spyStartShowingTotalsViewCalled = false
    func startShowingTotalsView() {
        spyStartShowingTotalsViewCalled = true
    }
}
