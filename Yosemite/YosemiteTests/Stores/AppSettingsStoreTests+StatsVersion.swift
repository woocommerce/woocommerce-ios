import XCTest
@testable import Yosemite
@testable import Storage

class AppSettingsStoreTests_StatsVersion: XCTestCase {
    /// Mockup Dispatcher!
    ///
    private var dispatcher: Dispatcher!

    /// Mockup Storage: InMemory
    ///
    private var storageManager: MockupStorageManager!

    /// Mockup File Storage: Load data in memory
    ///
    private var fileStorage: MockInMemoryStorage!

    /// Test subject
    ///
    private var subject: AppSettingsStore!

    override func setUp() {
        super.setUp()
        dispatcher = Dispatcher()
        storageManager = MockupStorageManager()
        fileStorage = MockInMemoryStorage()
        subject = AppSettingsStore(dispatcher: dispatcher!, storageManager: storageManager!, fileStorage: fileStorage!)
    }

    override func tearDown() {
        dispatcher = nil
        storageManager = nil
        fileStorage = nil
        subject = nil
        super.tearDown()
    }

    func testStatsVersionLastShownActions() {
        let siteID = 134

        let initialReadAction = AppSettingsAction.loadStatsVersionLastShown(siteID: siteID) { statsVersionLastShown in
            // Before any write actions, the stats version should be nil.
            XCTAssertNil(statsVersionLastShown)
        }
        subject.onAction(initialReadAction)

        let statsVersionToWrite = StatsVersion.v4
        let writeAction = AppSettingsAction.setStatsVersionLastShown(siteID: siteID, statsVersion: statsVersionToWrite)
        subject.onAction(writeAction)

        let readAction = AppSettingsAction.loadStatsVersionLastShown(siteID: siteID) { statsVersionLastShown in
            XCTAssertEqual(statsVersionLastShown, statsVersionToWrite)
        }
        subject.onAction(readAction)
    }

    func testStatsVersionLastShownWithTwoSites() {
        let siteID1 = 134
        let siteID2 = 268

        let statsVersionForSite1 = StatsVersion.v4
        let statsVersionForSite2 = StatsVersion.v3

        let writeActionForSite1 = AppSettingsAction.setStatsVersionLastShown(siteID: siteID1, statsVersion: statsVersionForSite1)
        subject.onAction(writeActionForSite1)
        let writeActionForSite2 = AppSettingsAction.setStatsVersionLastShown(siteID: siteID2, statsVersion: statsVersionForSite2)
        subject.onAction(writeActionForSite2)

        let readActionForSite1 = AppSettingsAction.loadStatsVersionLastShown(siteID: siteID1) { statsVersionLastShown in
            XCTAssertEqual(statsVersionLastShown, statsVersionForSite1)
        }
        subject.onAction(readActionForSite1)
        let readActionForSite2 = AppSettingsAction.loadStatsVersionLastShown(siteID: siteID2) { statsVersionLastShown in
            XCTAssertEqual(statsVersionLastShown, statsVersionForSite2)
        }
        subject.onAction(readActionForSite2)
    }

    func testResetStatsVersionStates() {
        let action = AppSettingsAction.resetStatsVersionStates
        subject.onAction(action)
        XCTAssertTrue(fileStorage!.deleteIsHit)
    }
}

// MARK: - Mock data

/// Mock implementation of the FileStorage protocol.
/// It reads and writes the data from and to an object in memory.
///
private final class MockInMemoryStorage: FileStorage {
    private let loader = PListFileStorage()

    /// A boolean value to test if a write to disk is requested
    ///
    var dataWriteIsHit: Bool = false

    /// A boolean value to test if a file deletion is requested
    ///
    var deleteIsHit: Bool = false

    private var data: Data?

    func data(for fileURL: URL) throws -> Data {
        guard let data = data else {
            throw AppSettingsStoreErrors.deletePreselectedProvider
        }
        return data
    }

    func write(_ data: Data, to fileURL: URL) throws {
        self.data = data
    }

    func deleteFile(at fileURL: URL) throws {
        data = nil
        deleteIsHit = true
    }
}
