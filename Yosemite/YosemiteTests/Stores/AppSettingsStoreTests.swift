import XCTest
@testable import Yosemite
@testable import Storage


/// Mock constants
///
private struct TestConstants {
    static let fileURL = Bundle(for: AppSettingsStoreTests.self)
        .url(forResource: "shipment-provider", withExtension: "plist")
    static let siteID = 156590080
    static let providerName = "post.at"

    static let newSiteID = 1234
    static let newProviderName = "Some provider"
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
}


private final class MockFileLoader: FileStorage {
    private let loader = PListFileStorage()

    var dataWriteIsHit: Bool = false

    func data(for fileURL: URL) throws -> Data {
        let result = try loader.data(for: TestConstants.fileURL!)
        return result
    }

    func write(_ data: Data, to fileURL: URL) throws {
        dataWriteIsHit = true
    }
}
