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

    var shouldReturnSiteSupportsLocalMobileReader: Bool = false
    func siteSupportsLocalMobileReader() -> Bool {
        return shouldReturnSiteSupportsLocalMobileReader
    }

    var shouldReturnDeviceSupportsLocalMobileReader: Bool = false
    func deviceSupportsLocalMobileReader() async -> Bool {
        return shouldReturnDeviceSupportsLocalMobileReader
    }
}
