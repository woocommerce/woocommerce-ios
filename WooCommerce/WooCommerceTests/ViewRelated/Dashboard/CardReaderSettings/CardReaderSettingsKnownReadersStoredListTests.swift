import XCTest
import Combine
@testable import WooCommerce

/// Mock constants
///
private struct TestConstants {
    static let mockReaderID = "CHB204909005931"
}

final class CardReaderSettingsKnownReadersStoredListTests: XCTestCase {

    func test_remembering_a_reader_publishes() {
        let mockStoresManager = MockAppSettingsStoresManager(sessionManager: SessionManager.testingInstance)

        let expectation = self.expectation(description: #function)
        expectation.expectedFulfillmentCount = 2

        var cancellable: AnyCancellable?
        let readerList = CardReaderSettingsKnownReadersStoredList(stores: mockStoresManager)

        var recordedObservations: [[String]] = []

        cancellable = readerList.$knownReaders.sink(receiveValue: { readers in
            recordedObservations.append(readers)
            expectation.fulfill()
        })

        readerList.rememberCardReader(cardReaderID: TestConstants.mockReaderID)

        wait(for: [expectation], timeout: Constants.expectationTimeout)
        cancellable?.cancel()

        XCTAssertEqual(recordedObservations, [[], [TestConstants.mockReaderID]])
    }

    func test_forgetting_a_reader_publishes() {
        let mockStoresManager = MockAppSettingsStoresManager(sessionManager: SessionManager.testingInstance)

        let expectation = self.expectation(description: #function)
        expectation.expectedFulfillmentCount = 3

        var cancellable: AnyCancellable?
        let readerList = CardReaderSettingsKnownReadersStoredList(stores: mockStoresManager)

        var recordedObservations: [[String]] = []

        cancellable = readerList.$knownReaders.sink(receiveValue: { readers in
            recordedObservations.append(readers)
            expectation.fulfill()
        })

        readerList.rememberCardReader(cardReaderID: TestConstants.mockReaderID)
        readerList.forgetCardReader(cardReaderID: TestConstants.mockReaderID)

        wait(for: [expectation], timeout: Constants.expectationTimeout)
        cancellable?.cancel()

        XCTAssertEqual(recordedObservations, [[], [TestConstants.mockReaderID], []])
    }
}
