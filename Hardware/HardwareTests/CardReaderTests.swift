import XCTest
@testable import Hardware

final class CardReaderTests: XCTestCase {
    func test_card_reader_maps_serial_number() {
        let mockReader = MockStripeCardReader.bbpos()
        let cardReader = CardReader(readerSource: mockReader)

        XCTAssertEqual(cardReader.serial, mockReader.serialNumber)
    }
}
