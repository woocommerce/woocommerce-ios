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
    /// Mock Dispatcher!
    ///
    private var dispatcher: Dispatcher?

    /// Mock Storage: InMemory
    ///
    private var storageManager: MockStorageManager?

    /// Mock File Storage: Load a plist in the test bundle
    ///
    private var fileStorage: MockInMemoryStorage?

    /// Test subject
    ///
    private var subject: AppSettingsStore?

    override func setUp() {
        super.setUp()
        dispatcher = Dispatcher()
        storageManager = MockStorageManager()
        fileStorage = MockInMemoryStorage()
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
                                    let fileData = self.fileStorage?.data.values.first as? [PreselectedProvider]
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
                                    let fileData = self.fileStorage?.data.values.first as? [PreselectedProvider]
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

    // MARK: - General App Settings

    func testItCanSaveTheAppInstallationDate() throws {
        // Given
        let date = Date(timeIntervalSince1970: 100)

        let (existingSettings, feedback) = createAppSettingAndGeneralFeedback(installationDate: Date(timeIntervalSince1970: 4_810),
                                                                              feedbackStatus: .given(Date(timeIntervalSince1970: 9_971_311)))
        try fileStorage?.write(existingSettings, to: expectedGeneralAppSettingsFileURL)

        // When
        var result: Result<Bool, Error>?
        let action = AppSettingsAction.setInstallationDateIfNecessary(date: date) { aResult in
            result = aResult
        }
        subject?.onAction(action)

        // Then
        XCTAssertTrue(try XCTUnwrap(result).isSuccess)
        XCTAssertTrue(try XCTUnwrap(result).get())

        let savedSettings: GeneralAppSettings = try XCTUnwrap(fileStorage?.data(for: expectedGeneralAppSettingsFileURL))
        XCTAssertEqual(date, savedSettings.installationDate)

        // The other properties should be kept
        XCTAssertEqual(savedSettings.feedbacks[feedback.name], feedback)
    }

    /// Test that the installationDate can still be saved even if there is no existing
    /// settings file.
    ///
    /// This has to be tested using a `FileStorage` that operates on real files instead of an
    /// in-memory storage. The in-memory storage does not fail if the given file URL does not exist.
    ///
    func test_it_can_save_the_installationDate_when_the_settings_file_does_not_exist() throws {
        // Given
        let date = Date(timeIntervalSince1970: 100)

        // Create our own infrastructure so we can inject `PListFileStorage`.
        let fileStorage = PListFileStorage()
        let storageManager = MockStorageManager()
        let dispatcher = Dispatcher()
        let store = AppSettingsStore(dispatcher: dispatcher, storageManager: storageManager, fileStorage: fileStorage)

        if FileManager.default.fileExists(atPath: expectedGeneralAppSettingsFileURL.path) {
            try fileStorage.deleteFile(at: expectedGeneralAppSettingsFileURL)
        }

        // When
        var result: Result<Bool, Error>?
        let action = AppSettingsAction.setInstallationDateIfNecessary(date: date) { aResult in
            result = aResult
        }
        store.onAction(action)

        // Then
        XCTAssertTrue(try XCTUnwrap(result).isSuccess)
        XCTAssertTrue(try XCTUnwrap(result).get())

        let savedSettings: GeneralAppSettings = try XCTUnwrap(fileStorage.data(for: expectedGeneralAppSettingsFileURL))
        XCTAssertEqual(date, savedSettings.installationDate)
    }

    func testItDoesNotSaveTheAppInstallationDateIfTheGivenDateIsNewer() throws {
        // Given
        let existingDate = Date(timeIntervalSince1970: 100)
        let newerDate = Date(timeIntervalSince1970: 101)

        try fileStorage?.deleteFile(at: expectedGeneralAppSettingsFileURL)

        // Save existingDate
        subject?.onAction(AppSettingsAction.setInstallationDateIfNecessary(date: existingDate, onCompletion: { _ in
            // noop
        }))

        // When
        // Save newerDate. This should be successful but the existingDate should be retained.
        var result: Result<Bool, Error>?
        let action = AppSettingsAction.setInstallationDateIfNecessary(date: newerDate) { aResult in
            result = aResult
        }
        subject?.onAction(action)

        // Then
        XCTAssertTrue(try XCTUnwrap(result).isSuccess)
        XCTAssertFalse(try XCTUnwrap(result).get())

        let savedSettings: GeneralAppSettings = try XCTUnwrap(fileStorage?.data(for: expectedGeneralAppSettingsFileURL))
        XCTAssertEqual(existingDate, savedSettings.installationDate)
        XCTAssertNotEqual(newerDate, savedSettings.installationDate)
    }

    func testGivenNoExistingSettingsThenItCanSaveTheAppInstallationDate() throws {
        // Given
        let date = Date(timeIntervalSince1970: 100)

        try fileStorage?.deleteFile(at: expectedGeneralAppSettingsFileURL)

        // When
        var result: Result<Bool, Error>?
        let action = AppSettingsAction.setInstallationDateIfNecessary(date: date) { aResult in
            result = aResult
        }
        subject?.onAction(action)

        // Then
        XCTAssertTrue(try XCTUnwrap(result).isSuccess)
        XCTAssertTrue(try XCTUnwrap(result).get())

        let savedSettings: GeneralAppSettings = try XCTUnwrap(fileStorage?.data(for: expectedGeneralAppSettingsFileURL))
        XCTAssertEqual(date, savedSettings.installationDate)
        XCTAssertTrue(savedSettings.feedbacks.isEmpty)
    }

    func test_it_can_update_the_general_feedback_given_date() throws {
        // Given
        let date = Date(timeIntervalSince1970: 300)

        let (existingSettings, feedback) = createAppSettingAndGeneralFeedback(installationDate: Date(timeIntervalSince1970: 1),
                                                                              feedbackStatus: .given(Date(timeIntervalSince1970: 999)))

        try fileStorage?.write(existingSettings, to: expectedGeneralAppSettingsFileURL)

        // When
        var result: Result<Void, Error>?
        let action = AppSettingsAction.updateFeedbackStatus(type: .general, status: .given(date)) { aResult in
            result = aResult
        }
        subject?.onAction(action)

        // Then
        XCTAssertTrue(try XCTUnwrap(result).isSuccess)

        let savedSettings: GeneralAppSettings = try XCTUnwrap(fileStorage?.data(for: expectedGeneralAppSettingsFileURL))
        let savedFeedback = try XCTUnwrap(savedSettings.feedbacks[feedback.name])
        XCTAssertEqual(.given(date), savedFeedback.status)

        // The other properties should be kept
        XCTAssertEqual(savedSettings.installationDate, existingSettings.installationDate)
    }

    /// This is more like a simple integration test because most of the logic is tested by
    /// `InAppFeedbackCardVisibilityUseCase`.
    ///
    func test_loadInAppFeedbackCardVisibility_returns_true_if_installationDate_is_more_than_90_days_ago() throws {
        // Given
        try fileStorage?.deleteFile(at: expectedGeneralAppSettingsFileURL)

        // Set the installation date. We'll set a very old one to make sure that it's older than the
        // Documents directory which is also considered as an "installation date".
        subject?.onAction(AppSettingsAction.setInstallationDateIfNecessary(date: Date.distantPast, onCompletion: { _ in
            // noop
        }))

        // When
        var shouldBeVisibleResult: Result<Bool, Error>?
        let action = AppSettingsAction.loadFeedbackVisibility(type: .general) { result in
            shouldBeVisibleResult = result
        }
        subject?.onAction(action)

        // Then
        XCTAssertTrue(try XCTUnwrap(shouldBeVisibleResult).isSuccess)
        XCTAssertTrue(try XCTUnwrap(shouldBeVisibleResult).get())
    }

    func test_loadFeedbackVisibility_for_productsM5_returns_true_after_marking_it_as_pending() throws {
        // Given
        try fileStorage?.deleteFile(at: expectedGeneralAppSettingsFileURL)
        let updateAction = AppSettingsAction.updateFeedbackStatus(type: .productsVariations, status: .pending) { _ in }
        subject?.onAction(updateAction)

        // When
        var visibilityResult: Result<Bool, Error>?
        let queryAction = AppSettingsAction.loadFeedbackVisibility(type: .productsVariations) { result in
            visibilityResult = result
        }
        subject?.onAction(queryAction)

        // Then
        let result = try XCTUnwrap(visibilityResult)
        XCTAssertTrue(result.isSuccess)
        XCTAssertTrue(try result.get())

    }

    func test_loadFeedbackVisibility_for_productsM5_returns_false_after_marking_it_as_dismissed() throws {
        // Given
        try fileStorage?.deleteFile(at: expectedGeneralAppSettingsFileURL)
        let updateAction = AppSettingsAction.updateFeedbackStatus(type: .productsVariations, status: .dismissed) { _ in }
        subject?.onAction(updateAction)

        // When
        var visibilityResult: Result<Bool, Error>?
        let queryAction = AppSettingsAction.loadFeedbackVisibility(type: .productsVariations) { result in
            visibilityResult = result
        }
        subject?.onAction(queryAction)

        // Then
        let result = try XCTUnwrap(visibilityResult)
        XCTAssertTrue(result.isSuccess)
        XCTAssertFalse(try result.get())

    }

    func test_loadFeedbackVisibility_for_productsM5_returns_false_after_marking_it_as_given() throws {
        // Given
        try fileStorage?.deleteFile(at: expectedGeneralAppSettingsFileURL)
        let updateAction = AppSettingsAction.updateFeedbackStatus(type: .productsVariations, status: .given(Date())) { _ in }
        subject?.onAction(updateAction)

        // When
        var visibilityResult: Result<Bool, Error>?
        let queryAction = AppSettingsAction.loadFeedbackVisibility(type: .productsVariations) { result in
            visibilityResult = result
        }
        subject?.onAction(queryAction)

        // Then
        let result = try XCTUnwrap(visibilityResult)
        XCTAssertTrue(result.isSuccess)
        XCTAssertFalse(try result.get())

    }
}

// MARK: - Utils

private extension AppSettingsStoreTests {
    var expectedGeneralAppSettingsFileURL: URL {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        return documents!.appendingPathComponent("general-app-settings.plist")
    }

    func createAppSettingAndGeneralFeedback(installationDate: Date?, feedbackStatus: FeedbackSettings.Status) -> (GeneralAppSettings, FeedbackSettings) {
        let feedback = FeedbackSettings(name: .general, status: feedbackStatus)
        let settings = GeneralAppSettings(installationDate: installationDate, feedbacks: [feedback.name: feedback])
        return (settings, feedback)
    }
}
