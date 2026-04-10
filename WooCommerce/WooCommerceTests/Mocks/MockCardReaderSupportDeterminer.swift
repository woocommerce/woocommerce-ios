import Foundation
import Yosemite
@testable import WooCommerce

final class MockCardReaderSupportDeterminer: CardReaderSupportDetermining {
    var shouldReturnLocationIsAuthorized = false
    var locationIsAuthorized: Bool {
        return shouldReturnLocationIsAuthorized
    }

    var shouldReturnConnectedReader: CardReader? = nil
    func connectedReader() async -> CardReader? {
        return shouldReturnConnectedReader
    }

    var shouldReturnHasPreviousTapToPayUsage: Bool = false
    func hasPreviousTapToPayUsage() async -> Bool {
        return shouldReturnHasPreviousTapToPayUsage
    }

    var shouldReturnSiteSupportsTapToPayReader: Bool = false
    func siteSupportsTapToPayReader() -> Bool {
        return shouldReturnSiteSupportsTapToPayReader
    }

    var shouldReturnDeviceSupportsTapToPayReader: Bool = false
    func deviceSupportsTapToPayReader() async -> Bool {
        return shouldReturnDeviceSupportsTapToPayReader
    }

    var mockFirstTapToPayTransactionDate: Date? = nil
    func firstTapToPayTransactionDate() async -> Date? {
        mockFirstTapToPayTransactionDate
    }

}
