import XCTest

@testable import Yosemite
@testable import Storage

/// Mock constants
///
private struct TestConstants {
    static let mockReaderID = "CHB204909005931"
}

final class AppSettingsStoreTests_CardReaderSettings: XCTestCase {

    /// Mock Dispatcher!
    ///
    private var dispatcher: Dispatcher!

    /// Mock Storage: InMemory
    ///
    private var storageManager: MockStorageManager!

    /// Mock File Storage: Load data in memory
    ///
    private var fileStorage: MockInMemoryStorage!

    /// Test subject
    ///
    private var subject: AppSettingsStore!

    override func setUp() {
        super.setUp()
        dispatcher = Dispatcher()
        storageManager = MockStorageManager()
        fileStorage = MockInMemoryStorage()
        subject = AppSettingsStore(dispatcher: dispatcher, storageManager: storageManager, fileStorage: fileStorage)
    }

    override func tearDown() {
        dispatcher = nil
        storageManager = nil
        fileStorage = nil
        subject = nil
        super.tearDown()
    }

    func test_loading_card_reader_without_previous_data_returns_nil() {

        let expectation = self.expectation(description: #function)

        let loadAction = AppSettingsAction.loadCardReader { result in
            XCTAssertTrue(result.isSuccess)
            if case .success(let readerID) = result {
                XCTAssertTrue(readerID == nil)
                expectation.fulfill()
            }
        }

        subject.onAction(loadAction)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    func test_remember_card_reader_remembers_the_card_reader() {

        let expectation = self.expectation(description: #function)

        let loadAction = AppSettingsAction.loadCardReader { result in
            XCTAssertTrue(result.isSuccess)
            if case .success(let readerID) = result {
                XCTAssertTrue(readerID == TestConstants.mockReaderID)
                expectation.fulfill()
            }
        }

        let rememberAction = AppSettingsAction.rememberCardReader(cardReaderID: TestConstants.mockReaderID, onCompletion: { result in
            XCTAssertTrue(result.isSuccess)
            self.subject.onAction(loadAction)
        })

        subject.onAction(rememberAction)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    func test_forget_card_reader_forgets_the_card_reader() {

        let expectation = self.expectation(description: #function)

        let loadAction = AppSettingsAction.loadCardReader { result in
            XCTAssertTrue(result.isSuccess)
            if case .success(let readerID) = result {
                XCTAssertTrue(readerID == nil)
                expectation.fulfill()
            }
        }

        let forgetAction = AppSettingsAction.forgetCardReader(onCompletion: { result in
            XCTAssertTrue(result.isSuccess)
            self.subject.onAction(loadAction)
        })

        let rememberAction = AppSettingsAction.rememberCardReader(cardReaderID: TestConstants.mockReaderID, onCompletion: { result in
            XCTAssertTrue(result.isSuccess)
            self.subject.onAction(forgetAction)
        })

        subject.onAction(rememberAction)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }
}
