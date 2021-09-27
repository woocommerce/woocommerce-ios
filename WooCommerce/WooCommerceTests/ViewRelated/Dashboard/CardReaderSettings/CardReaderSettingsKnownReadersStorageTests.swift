import XCTest
import Combine
@testable import WooCommerce

/// Mock constants
///
private struct TestConstants {
    static let mockReaderID = "CHB204909005931"
    static let secondMockReaderID = "CHB204909005932"
}

final class CardReaderSettingsKnownReadersStorageTests: XCTestCase {

    func test_subscribing_publishes_initial_empty_value() {
        let mockStoresManager = MockAppSettingsStoresManager(sessionManager: SessionManager.testingInstance)

        let expectation = self.expectation(description: #function)

        var cancellable: AnyCancellable?
        let readerList = CardReaderSettingsKnownReaderStorage(stores: mockStoresManager)

        cancellable = readerList.knownReader.sink(receiveValue: { readerID in
            guard readerID == nil else {
                return
            }
            expectation.fulfill()
        })

        wait(for: [expectation], timeout: Constants.expectationTimeout)

        cancellable?.cancel()
    }

    func test_subscribing_publishes_initial_known_value() {
        let mockStoresManager = MockAppSettingsStoresManager(sessionManager: SessionManager.testingInstance, knownReaderID: TestConstants.mockReaderID)

        let expectation = self.expectation(description: #function)
        expectation.expectedFulfillmentCount = 1

        var cancellable: AnyCancellable?
        let readerList = CardReaderSettingsKnownReaderStorage(stores: mockStoresManager)

        var recordedObservations: [String] = []

        cancellable = readerList.knownReader.sink(receiveValue: { readerID in
            guard let readerID = readerID else {
                return
            }
            recordedObservations.append(readerID)
            expectation.fulfill()
        })

        wait(for: [expectation], timeout: Constants.expectationTimeout)

        cancellable?.cancel()

        XCTAssertEqual(recordedObservations, [TestConstants.mockReaderID])
    }

    func test_remembering_a_reader_publishes_change() {
        let mockStoresManager = MockAppSettingsStoresManager(sessionManager: SessionManager.testingInstance, knownReaderID: TestConstants.mockReaderID)

        let expectation = self.expectation(description: #function)
        expectation.expectedFulfillmentCount = 2

        var cancellable: AnyCancellable?
        let readerList = CardReaderSettingsKnownReaderStorage(stores: mockStoresManager)

        var recordedObservations: [String] = []

        cancellable = readerList.knownReader.sink(receiveValue: { readerID in
            guard let readerID = readerID else {
                return
            }
            recordedObservations.append(readerID)
            expectation.fulfill()
        })

        readerList.rememberCardReader(cardReaderID: TestConstants.secondMockReaderID)

        wait(for: [expectation], timeout: Constants.expectationTimeout)

        cancellable?.cancel()

        XCTAssertEqual(recordedObservations, [TestConstants.mockReaderID, TestConstants.secondMockReaderID])
    }

    func test_forgetting_a_reader_publishes_change() {
        let mockStoresManager = MockAppSettingsStoresManager(sessionManager: SessionManager.testingInstance)

        let expectation = self.expectation(description: #function)
        expectation.expectedFulfillmentCount = 3

        var cancellable: AnyCancellable?
        let readerList = CardReaderSettingsKnownReaderStorage(stores: mockStoresManager)

        var recordedObservations: [String] = []

        cancellable = readerList.knownReader.sink(receiveValue: { readerID in
            guard let readerID = readerID else {
                recordedObservations.append("NIL")
                expectation.fulfill()
                return
            }
            recordedObservations.append(readerID)
            expectation.fulfill()
        })

        readerList.rememberCardReader(cardReaderID: TestConstants.mockReaderID)
        readerList.forgetCardReader()

        wait(for: [expectation], timeout: Constants.expectationTimeout)
        cancellable?.cancel()

        XCTAssertEqual(recordedObservations, ["NIL", TestConstants.mockReaderID, "NIL"])
    }
}
