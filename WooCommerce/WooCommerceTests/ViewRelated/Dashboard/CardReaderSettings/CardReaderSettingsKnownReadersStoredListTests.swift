import XCTest
import Combine
@testable import WooCommerce

/// Mock constants
///
private struct TestConstants {
    static let mockReaderID = "CHB204909005931"
    static let secondMockReaderID = "CHB204909005932"
}

final class CardReaderSettingsKnownReadersStoredListTests: XCTestCase {

    func test_subscribing_publishes_initial_empty_value() {
        let mockStoresManager = MockAppSettingsStoresManager(sessionManager: SessionManager.testingInstance)

        let expectation = self.expectation(description: #function)

        var cancellable: AnyCancellable?
        let readerList = CardReaderSettingsKnownReadersStoredList(stores: mockStoresManager)

        var recordedObservations: [[String]] = []

        cancellable = readerList.knownReaders.sink(receiveValue: { readers in
            recordedObservations.append(readers)
            expectation.fulfill()
        })

        wait(for: [expectation], timeout: Constants.expectationTimeout)

        cancellable?.cancel()

        XCTAssertEqual(recordedObservations, [[]])
    }

    func test_subscribing_publishes_initial_known_value() {
        let mockStoresManager = MockAppSettingsStoresManager(sessionManager: SessionManager.testingInstance, knownReaderIDs: [TestConstants.mockReaderID])

        let expectation = self.expectation(description: #function)
        expectation.expectedFulfillmentCount = 1

        var cancellable: AnyCancellable?
        let readerList = CardReaderSettingsKnownReadersStoredList(stores: mockStoresManager)

        var recordedObservations: [[String]] = []

        cancellable = readerList.knownReaders.sink(receiveValue: { readers in
            recordedObservations.append(readers)
            expectation.fulfill()
        })

        wait(for: [expectation], timeout: Constants.expectationTimeout)

        cancellable?.cancel()

        XCTAssertEqual(recordedObservations, [[TestConstants.mockReaderID]])
    }

    func test_remembering_a_reader_publishes_change() {
        let mockStoresManager = MockAppSettingsStoresManager(sessionManager: SessionManager.testingInstance)

        let expectation = self.expectation(description: #function)
        expectation.expectedFulfillmentCount = 2

        var cancellable: AnyCancellable?
        let readerList = CardReaderSettingsKnownReadersStoredList(stores: mockStoresManager)

        var recordedObservations: [[String]] = []

        cancellable = readerList.knownReaders.sink(receiveValue: { readers in
            recordedObservations.append(readers)
            expectation.fulfill()
        })

        readerList.rememberCardReader(cardReaderID: TestConstants.mockReaderID)

        wait(for: [expectation], timeout: Constants.expectationTimeout)

        cancellable?.cancel()

        XCTAssertEqual(recordedObservations, [[], [TestConstants.mockReaderID]])
    }

    func test_remembering_mulitple_readers_publishes_most_recent_reader_only() {
        let mockStoresManager = MockAppSettingsStoresManager(sessionManager: SessionManager.testingInstance)

        let expectation = self.expectation(description: #function)
        expectation.expectedFulfillmentCount = 3

        var cancellable: AnyCancellable?
        let readerList = CardReaderSettingsKnownReadersStoredList(stores: mockStoresManager)

        var recordedObservations: [[String]] = []

        cancellable = readerList.knownReaders.sink(receiveValue: { readers in
            recordedObservations.append(readers)
            expectation.fulfill()
        })

        readerList.rememberCardReader(cardReaderID: TestConstants.mockReaderID)
        readerList.rememberCardReader(cardReaderID: TestConstants.secondMockReaderID)

        wait(for: [expectation], timeout: Constants.expectationTimeout)

        cancellable?.cancel()

        XCTAssertEqual(recordedObservations, [[], [TestConstants.mockReaderID], [TestConstants.secondMockReaderID]])
    }


    func test_forgetting_a_reader_publishes_change() {
        let mockStoresManager = MockAppSettingsStoresManager(sessionManager: SessionManager.testingInstance)

        let expectation = self.expectation(description: #function)
        expectation.expectedFulfillmentCount = 3

        var cancellable: AnyCancellable?
        let readerList = CardReaderSettingsKnownReadersStoredList(stores: mockStoresManager)

        var recordedObservations: [[String]] = []

        cancellable = readerList.knownReaders.sink(receiveValue: { readers in
            recordedObservations.append(readers)
            expectation.fulfill()
        })

        readerList.rememberCardReader(cardReaderID: TestConstants.mockReaderID)
        readerList.forgetCardReader()

        wait(for: [expectation], timeout: Constants.expectationTimeout)
        cancellable?.cancel()

        XCTAssertEqual(recordedObservations, [[], [TestConstants.mockReaderID], []])
    }
}
