import XCTest
@testable import Yosemite
@testable import Storage

final class AppSettingsStoreTests_StatsVersion: XCTestCase {
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
        let siteID: Int64 = 134

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
        let siteID1: Int64 = 134
        let siteID2: Int64 = 268

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

    func testStatsVersionBannerVisibilityActions() {
        let initialV3ToV4ReadAction = AppSettingsAction.loadStatsVersionBannerVisibility(banner: .v3ToV4, onCompletion: { shouldShowBanner in
            // Before any write actions, the default should be to show the banner.
            XCTAssertTrue(shouldShowBanner)
        })
        subject.onAction(initialV3ToV4ReadAction)

        let initialV4ToV3ReadAction = AppSettingsAction.loadStatsVersionBannerVisibility(banner: .v4ToV3, onCompletion: { shouldShowBanner in
            // Before any write actions, the default should be to show the banner.
            XCTAssertTrue(shouldShowBanner)
        })
        subject.onAction(initialV4ToV3ReadAction)

        let v3ToV4WriteAction = AppSettingsAction.setStatsVersionBannerVisibility(banner: .v3ToV4, shouldShowBanner: false)
        subject.onAction(v3ToV4WriteAction)

        let v3ToV4AfterHidingV3ToV4ReadAction = AppSettingsAction.loadStatsVersionBannerVisibility(banner: .v3ToV4, onCompletion: { shouldShowBanner in
            XCTAssertFalse(shouldShowBanner)
        })
        subject.onAction(v3ToV4AfterHidingV3ToV4ReadAction)

        let v4ToV3AfterHidingV3ToV4ReadAction = AppSettingsAction.loadStatsVersionBannerVisibility(banner: .v4ToV3, onCompletion: { shouldShowBanner in
            XCTAssertTrue(shouldShowBanner)
        })
        subject.onAction(v4ToV3AfterHidingV3ToV4ReadAction)

        let v4ToV3WriteAction = AppSettingsAction.setStatsVersionBannerVisibility(banner: .v4ToV3, shouldShowBanner: false)
        subject.onAction(v4ToV3WriteAction)

        let v3ToV4AfterHidingV4ToV3ReadAction = AppSettingsAction.loadStatsVersionBannerVisibility(banner: .v3ToV4, onCompletion: { shouldShowBanner in
            XCTAssertFalse(shouldShowBanner)
        })
        subject.onAction(v3ToV4AfterHidingV4ToV3ReadAction)

        let v4ToV3AfterHidingV4ToV3ReadAction = AppSettingsAction.loadStatsVersionBannerVisibility(banner: .v4ToV3, onCompletion: { shouldShowBanner in
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
