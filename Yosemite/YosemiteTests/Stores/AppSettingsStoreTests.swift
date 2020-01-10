import XCTest
@testable import Yosemite
@testable import Storage


/// Mock constants
///
private struct TestConstants {
    static let fileURL = Bundle(for: AppSettingsStoreTests.self)
        .url(forResource: "shipment-provider", withExtension: "plist")
    static let customFileURL = Bundle(for: AppSettingsStoreTests.self)
        .url(forResource: "custom-shipment-provider", withExtension: "plist")
    static let siteID: Int64 = 156590080
    static let providerName = "post.at"
    static let providerURL = "http://some.where"

    static let newSiteID: Int64 = 1234
    static let newProviderName = "Some provider"
    static let newProviderURL = "http://some.where"
}


/// AppSettingsStore unit tests
///
final class AppSettingsStoreTests: XCTestCase {
    /// Mockup Dispatcher!
    ///
    private var dispatcher: Dispatcher?

    /// Mockup Storage: InMemory
    ///
    private var storageManager: MockupStorageManager?

    /// Mockup File Storage: Load a plist in the test bundle
    ///
    private var fileStorage: MockFileLoader?

    /// Test subject
    ///
    private var subject: AppSettingsStore?

    override func setUp() {
        super.setUp()
        dispatcher = Dispatcher()
        storageManager = MockupStorageManager()
        fileStorage = MockFileLoader()
        subject = AppSettingsStore(dispatcher: dispatcher!, storageManager: storageManager!, fileStorage: fileStorage!)
        subject?.selectedProvidersURL = TestConstants.fileURL!
        subject?.customSelectedProvidersURL = TestConstants.customFileURL!
    }

    override func tearDown() {
        dispatcher = nil
        storageManager = nil
        fileStorage = nil
        subject = nil
        super.tearDown()
    }

    func testFileStorageIsRequestedToWriteWhenAddingANewShipmentProvider() {
        let expectation = self.expectation(description: "A write is requested")

        let action = AppSettingsAction.addTrackingProvider(siteID: TestConstants.newSiteID,
                                                           providerName: TestConstants.newProviderName) { error in
                                                            XCTAssertNil(error)

                                                            if self.fileStorage?.dataWriteIsHit == true {
                                                                expectation.fulfill()
                                                            }
        }

        subject?.onAction(action)

        waitForExpectations(timeout: 2, handler: nil)
    }

    func testFileStorageIsRequestedToWriteWhenAddingANewCustomShipmentProvider() {
        let expectation = self.expectation(description: "A write is requested")

        let action = AppSettingsAction.addCustomTrackingProvider(siteID: TestConstants.newSiteID,
                                                                 providerName: TestConstants.newProviderName,
                                                                 providerURL: TestConstants.newProviderURL) { error in
                                                            XCTAssertNil(error)

                                                            if self.fileStorage?.dataWriteIsHit == true {
                                                                expectation.fulfill()
                                                            }
        }

        subject?.onAction(action)

        waitForExpectations(timeout: 2, handler: nil)
    }

    func testFileStorageIsRequestedToWriteWhenAddingAShipmentProviderForExistingSite() {
        let expectation = self.expectation(description: "A write is requested")

        let action = AppSettingsAction.addTrackingProvider(siteID: TestConstants.siteID,
                                                           providerName: TestConstants.providerName) { error in
                                                            XCTAssertNil(error)

                                                            if self.fileStorage?.dataWriteIsHit == true {
                                                                expectation.fulfill()
                                                            }
        }

        subject?.onAction(action)

        waitForExpectations(timeout: 2, handler: nil)
    }

    func testFileStorageIsRequestedToWriteWhenAddingACustomShipmentProviderForExistingSite() {
        let expectation = self.expectation(description: "A write is requested")

        let action = AppSettingsAction.addCustomTrackingProvider(siteID: TestConstants.siteID,
                                                           providerName: TestConstants.providerName,
                                                           providerURL: TestConstants.providerURL) { error in
                                                            XCTAssertNil(error)

                                                            if self.fileStorage?.dataWriteIsHit == true {
                                                                expectation.fulfill()
                                                            }
        }

        subject?.onAction(action)

        waitForExpectations(timeout: 2, handler: nil)
    }

    func testAddingNewProviderToExistingSiteUpdatesFile() {
        let expectation = self.expectation(description: "File is updated")

        let action = AppSettingsAction
            .addTrackingProvider(siteID: TestConstants.siteID,
                                 providerName: TestConstants.newProviderName) { error in
                                    XCTAssertNil(error)
                                    let fileData = self.fileStorage?.fileData
                                    let updatedProvider = fileData?.filter({ $0.siteID == TestConstants.siteID}).first

                                    if updatedProvider?.providerName == TestConstants.newProviderName {
                                        expectation.fulfill()
                                    }

        }

        subject?.onAction(action)

        waitForExpectations(timeout: 2, handler: nil)
    }

    func testAddingNewCustomProviderToExistingSiteUpdatesFile() {
        let expectation = self.expectation(description: "File is updated")

        let action = AppSettingsAction
            .addCustomTrackingProvider(siteID: TestConstants.siteID,
                                 providerName: TestConstants.newProviderName,
                                 providerURL: TestConstants.newProviderURL) { error in
                                    XCTAssertNil(error)
                                    let fileData = self.fileStorage?.fileData
                                    let updatedProvider = fileData?.filter({ $0.siteID == TestConstants.siteID}).first

                                    if updatedProvider?.providerName == TestConstants.newProviderName {
                                        expectation.fulfill()
                                    }

        }

        subject?.onAction(action)

        waitForExpectations(timeout: 2, handler: nil)
    }

    func testRestoreResetProvidersHitsClearFile() {
        let expectation = self.expectation(description: "File is updated")

        let action = AppSettingsAction.resetStoredProviders { error in
            XCTAssertNil(error)

            if self.fileStorage?.deleteIsHit == true {
                expectation.fulfill()
            }
        }

        subject?.onAction(action)

        waitForExpectations(timeout: 2, handler: nil)
    }
}

// MARK: - Mock data

/// Mock implementation of the FileStorage protocol.
/// It loads the contents of a file in the test bundle
/// and simulates writes to the same file
///
private final class MockFileLoader: FileStorage {
    private let loader = PListFileStorage()

    /// A boolean value to test if a write to disk is requested
    ///
    var dataWriteIsHit: Bool = false

    /// A boolean value to test if a file deletion is requested
    ///
    var deleteIsHit: Bool = false

    /// List of `PreselectedProvider` materialised from the data passed
    /// tpo `write()`
    ///
    var fileData = [PreselectedProvider]()

    func data(for fileURL: URL) throws -> Data {
        let result = try loader.data(for: TestConstants.fileURL!)
        return result
    }

    func write(_ data: Data, to fileURL: URL) throws {
        dataWriteIsHit = true
        decode(data)
    }

    private func decode(_ data: Data) {
        let decoder = PropertyListDecoder()
        fileData = try! decoder.decode([PreselectedProvider].self, from: data)
    }

    func deleteFile(at fileURL: URL) throws {
        deleteIsHit = true
    }

}
