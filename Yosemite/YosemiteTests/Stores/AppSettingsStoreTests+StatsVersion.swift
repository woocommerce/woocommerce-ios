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

        let initialReadAction = AppSettingsAction.loadInitialStatsVersionToShow(siteID: siteID) { statsVersionLastShown in
            // Before any write actions, the stats version should be nil.
            XCTAssertNil(statsVersionLastShown)
        }
        subject.onAction(initialReadAction)

        let statsVersionToWrite = StatsVersion.v4
        let writeAction = AppSettingsAction.setStatsVersionLastShown(siteID: siteID, statsVersion: statsVersionToWrite)
        subject.onAction(writeAction)

        let readAction = AppSettingsAction.loadInitialStatsVersionToShow(siteID: siteID) { statsVersionLastShown in
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

        let readActionForSite1 = AppSettingsAction.loadInitialStatsVersionToShow(siteID: siteID1) { statsVersionLastShown in
            XCTAssertEqual(statsVersionLastShown, statsVersionForSite1)
        }
        subject.onAction(readActionForSite1)
        let readActionForSite2 = AppSettingsAction.loadInitialStatsVersionToShow(siteID: siteID2) { statsVersionLastShown in
            XCTAssertEqual(statsVersionLastShown, statsVersionForSite2)
        }
        subject.onAction(readActionForSite2)
    }

    func testStatsVersionEligibleActions() {
        let siteID = 134

        let initialReadAction = AppSettingsAction.loadStatsVersionEligible(siteID: siteID) { eligibleStatsVersion in
            // Before any write actions, the stats version should be nil.
            XCTAssertNil(eligibleStatsVersion)
        }
        subject.onAction(initialReadAction)

        let statsVersionToWrite = StatsVersion.v4
        let writeAction = AppSettingsAction.setStatsVersionEligible(siteID: siteID, statsVersion: statsVersionToWrite)
        subject.onAction(writeAction)

        let readAction = AppSettingsAction.loadStatsVersionEligible(siteID: siteID) { eligibleStatsVersion in
            XCTAssertEqual(eligibleStatsVersion, statsVersionToWrite)
        }
        subject.onAction(readAction)
    }

    func testStatsVersionBannerVisibilityActions() {
        let initialV3ToV4ReadAction = AppSettingsAction.loadStatsV3ToV4BannerVisibility(onCompletion: { shouldShowBanner in
            // Before any write actions, the default should be to show the banner.
            XCTAssertTrue(shouldShowBanner)
        })
        subject.onAction(initialV3ToV4ReadAction)

        let initialV4ToV3ReadAction = AppSettingsAction.loadStatsV4ToV3BannerVisibility(onCompletion: { shouldShowBanner in
            // Before any write actions, the default should be to show the banner.
            XCTAssertTrue(shouldShowBanner)
        })
        subject.onAction(initialV4ToV3ReadAction)

        let v3ToV4WriteAction = AppSettingsAction.setStatsV3ToV4BannerVisibility(shouldShowBanner: false)
        subject.onAction(v3ToV4WriteAction)

        let v3ToV4AfterHidingV3ToV4ReadAction = AppSettingsAction.loadStatsV3ToV4BannerVisibility(onCompletion: { shouldShowBanner in
            XCTAssertFalse(shouldShowBanner)
        })
        subject.onAction(v3ToV4AfterHidingV3ToV4ReadAction)

        let v4ToV3AfterHidingV3ToV4ReadAction = AppSettingsAction.loadStatsV4ToV3BannerVisibility(onCompletion: { shouldShowBanner in
            XCTAssertTrue(shouldShowBanner)
        })
        subject.onAction(v4ToV3AfterHidingV3ToV4ReadAction)

        let v4ToV3WriteAction = AppSettingsAction.setStatsV4ToV3BannerVisibility(shouldShowBanner: false)
        subject.onAction(v4ToV3WriteAction)

        let v3ToV4AfterHidingV4ToV3ReadAction = AppSettingsAction.loadStatsV3ToV4BannerVisibility(onCompletion: { shouldShowBanner in
            XCTAssertFalse(shouldShowBanner)
        })
        subject.onAction(v3ToV4AfterHidingV4ToV3ReadAction)

        let v4ToV3AfterHidingV4ToV3ReadAction = AppSettingsAction.loadStatsV4ToV3BannerVisibility(onCompletion: { shouldShowBanner in
            XCTAssertFalse(shouldShowBanner)
        })
        subject.onAction(v4ToV3AfterHidingV4ToV3ReadAction)
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

    private var dataByFileURL: [URL: Data] = [:]

    func data(for fileURL: URL) throws -> Data {
        guard let data = dataByFileURL[fileURL] else {
            throw AppSettingsStoreErrors.deletePreselectedProvider
        }
        return data
    }

    func write(_ data: Data, to fileURL: URL) throws {
        dataByFileURL[fileURL] = data
    }

    func deleteFile(at fileURL: URL) throws {
        dataByFileURL = [:]
        deleteIsHit = true
    }
}
