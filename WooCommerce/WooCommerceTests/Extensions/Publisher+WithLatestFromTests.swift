import Combine
import XCTest
@testable import WooCommerce

class Publisher_WithLatestFromTests: XCTestCase {

    @Published var firstStream = 0
    @Published var secondStream = "🍕"
    @Published var resultStream = (0, "🍕")

    override func tearDown() {
        firstStream = 0
        secondStream = "🍕"
        resultStream = (firstStream, secondStream)
    }

    func test_withLatestFrom_emits_new_event_when_first_stream_emits_new_event_and_ignores_subsequent_events_of_second_stream() {
        // Given
        $firstStream.withLatestFrom($secondStream)
            .assign(to: &$resultStream)

        XCTAssertEqual(resultStream.0, 0)
        XCTAssertEqual(resultStream.1, "🍕")

        // When
        firstStream = 1
        secondStream = "🥗"

        // Then
        XCTAssertEqual(resultStream.0, 1)
        XCTAssertEqual(resultStream.1, "🍕")
    }

    func test_withLatestFrom_emits_latest_event_from_second_stream_when_first_stream_emits_new_event() {
        // Given
        $firstStream.withLatestFrom($secondStream)
            .assign(to: &$resultStream)

        firstStream = 1
        secondStream = "🥗"
        XCTAssertEqual(resultStream.0, 1)
        XCTAssertEqual(resultStream.1, "🍕")

        // When
        firstStream = 2

        // Then
        XCTAssertEqual(resultStream.0, 2)
        XCTAssertEqual(resultStream.1, "🥗")
    }
}
