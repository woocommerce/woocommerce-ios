import Combine
import XCTest
@testable import WooCommerce

class Publisher_WithLatestFromTests: XCTestCase {

    var cancellable: AnyCancellable?
    @Published var firstStream = 0
    @Published var secondStream = "🍕"
    let resultStream = CurrentValueSubject<(Int, String), Never>((0, "🍕"))

    override func tearDown() {
        firstStream = 0
        secondStream = "🍕"
        resultStream.send((firstStream, secondStream))
    }

    func test_withLatestFrom_emits_new_event_when_first_stream_emits_new_event_and_ignores_subsequent_events_of_second_stream() {
        // Given
        cancellable = $firstStream.withLatestFrom($secondStream)
            .sink { [weak self] first, second in
                self?.resultStream.send((first, second))
            }

        XCTAssertEqual(resultStream.value.0, 0)
        XCTAssertEqual(resultStream.value.1, "🍕")

        // When
        firstStream = 1
        secondStream = "🥗"

        // Then
        XCTAssertEqual(resultStream.value.0, 1)
        XCTAssertEqual(resultStream.value.1, "🍕")
    }

    func test_withLatestFrom_emits_latest_event_from_second_stream_when_first_stream_emits_new_event() {
        // Given
        cancellable = $firstStream.withLatestFrom($secondStream)
            .sink { [weak self] first, second in
                self?.resultStream.send((first, second))
            }
        firstStream = 1
        secondStream = "🥗"
        XCTAssertEqual(resultStream.value.0, 1)
        XCTAssertEqual(resultStream.value.1, "🍕")

        // When
        firstStream = 2

        // Then
        XCTAssertEqual(resultStream.value.0, 2)
        XCTAssertEqual(resultStream.value.1, "🥗")
    }
}
