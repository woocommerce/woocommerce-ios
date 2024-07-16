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

    /// Mock General Settings Storage: Load data in memory
    ///
    private var generalAppSettings: GeneralAppSettingsStorage?

    /// Test subject
    ///
    private var subject: AppSettingsStore?

    override func setUp() {
        super.setUp()
        dispatcher = Dispatcher()
        storageManager = MockStorageManager()
        fileStorage = MockInMemoryStorage()
        generalAppSettings = GeneralAppSettingsStorage(fileStorage: fileStorage!)
        subject = AppSettingsStore(dispatcher: dispatcher!, storageManager: storageManager!, fileStorage: fileStorage!, generalAppSettings: generalAppSettings!)
        subject?.selectedProvidersURL = TestConstants.fileURL!
        subject?.customSelectedProvidersURL = TestConstants.customFileURL!
    }

    override func tearDown() {
        dispatcher = nil
        storageManager = nil
        fileStorage = nil
        generalAppSettings = nil
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
        let generalAppSettings = GeneralAppSettingsStorage(fileStorage: fileStorage)
        let dispatcher = Dispatcher()
        let store = AppSettingsStore(dispatcher: dispatcher, storageManager: storageManager, fileStorage: fileStorage, generalAppSettings: generalAppSettings)

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

    func test_loadOrderAddOnsSwitchState_returns_false_on_new_generalAppSettings() throws {
        // Given
        try fileStorage?.deleteFile(at: expectedGeneralAppSettingsFileURL)

        // When
        let result: Result<Bool, Error> = waitFor { promise in
            let action = AppSettingsAction.loadOrderAddOnsSwitchState { result in
                promise(result)
            }
            self.subject?.onAction(action)
        }

        // Then
        let isEnabled = try result.get()
        XCTAssertFalse(isEnabled)
    }

    func test_loadOrderAddOnsSwitchState_returns_true_after_updating_switch_state_as_true() throws {
        // Given
        try fileStorage?.deleteFile(at: expectedGeneralAppSettingsFileURL)
        let updateAction = AppSettingsAction.setOrderAddOnsFeatureSwitchState(isEnabled: true, onCompletion: { _ in })
        subject?.onAction(updateAction)

        // When
        let result: Result<Bool, Error> = waitFor { promise in
            let action = AppSettingsAction.loadOrderAddOnsSwitchState { result in
                promise(result)
            }
            self.subject?.onAction(action)
        }

        // Then
        let isEnabled = try result.get()
        XCTAssertTrue(isEnabled)
    }

    func test_loadPointOfSaleSwitchState_isEnabled_when_new_generalAppSettings_then_returns_false() throws {
        // Given
        try fileStorage?.deleteFile(at: expectedGeneralAppSettingsFileURL)

        // When
        let result: Result<Bool, Error> = waitFor { promise in
            let action = AppSettingsAction.loadPointOfSaleSwitchState { result in
                promise(result)
            }
            self.subject?.onAction(action)
        }

        // Then
        let isEnabled = try result.get()
        XCTAssertFalse(isEnabled)
    }

    func test_loadPointOfSaleSwitchState_isEnabled_when_setPointOfSaleSwitchState_to_true_then_returns_true() throws {
        // Given
        try fileStorage?.deleteFile(at: expectedGeneralAppSettingsFileURL)
        let updateAction = AppSettingsAction.setPointOfSaleSwitchState(isEnabled: true, onCompletion: { _ in })
        subject?.onAction(updateAction)

        // When
        let result: Result<Bool, Error> = waitFor { promise in
            let action = AppSettingsAction.loadPointOfSaleSwitchState { result in
                promise(result)
            }
            self.subject?.onAction(action)
        }

        // Then
        let isEnabled = try result.get()
        XCTAssertTrue(isEnabled)
    }

    func test_loadJetpackBenefitsBannerVisibility_returns_true_on_new_generalAppSettings() throws {
        // Given
        // Deletes any pre-existing app settings.
        try fileStorage?.deleteFile(at: expectedGeneralAppSettingsFileURL)

        // GMT - Sunday, November 28, 2021 1:25:24 PM
        let currentTime = Date(timeIntervalSince1970: 1638105924)
        let calendar = Calendar(identifier: .gregorian)

        // When
        let isVisible: Bool = waitFor { promise in
            let action = AppSettingsAction.loadJetpackBenefitsBannerVisibility(currentTime: currentTime, calendar: calendar) { isVisible in
                promise(isVisible)
            }
            self.subject?.onAction(action)
        }

        // Then
        // The banner is visible if there are no pre-existing app settings.
        XCTAssertTrue(isVisible)
    }

    func test_loadJetpackBenefitsBannerVisibility_returns_true_after_setting_last_dismissed_date_exactly_five_days_ago_without_dst() throws {
        // Given
        try fileStorage?.deleteFile(at: expectedGeneralAppSettingsFileURL)

        // GMT - Tuesday, November 23, 2021 1:25:24 PM
        let lastDismissedTime = Date(timeIntervalSince1970: 1637673924)
        // GMT - Sunday, November 28, 2021 1:25:24 PM - exactly five days after the last dismissed date without DST
        let currentTime = Date(timeIntervalSince1970: 1638105924)
        let calendar: Calendar = {
            var calendar = Calendar(identifier: .gregorian)
            guard let timeZoneWithoutDaylightSavingTime = TimeZone(identifier: "Asia/Taipei") else {
                XCTFail("Unexpected time zone.")
                return calendar
            }
            calendar.timeZone = timeZoneWithoutDaylightSavingTime
            return calendar
        }()

        let updateAction = AppSettingsAction.setJetpackBenefitsBannerLastDismissedTime(time: lastDismissedTime)
        subject?.onAction(updateAction)

        // When
        let isVisible: Bool = waitFor { promise in
            let action = AppSettingsAction.loadJetpackBenefitsBannerVisibility(currentTime: currentTime, calendar: calendar) { isVisible in
                promise(isVisible)
            }
            self.subject?.onAction(action)
        }

        // Then
        XCTAssertTrue(isVisible)
    }

    /// Tests an edge case where the time interval since the last dismissed date is less than 5 24-hour days, but is exactly 5 days on calendar with daylight
    /// saving time.
    func test_loadJetpackBenefitsBannerVisibility_returns_false_after_setting_last_dismissed_date_exactly_five_24hr_days_ago() throws {
        // Given
        try fileStorage?.deleteFile(at: expectedGeneralAppSettingsFileURL)

        // America/New York (EDT) - November 03, 2021 09:43:17 AM
        let lastDismissedTime = Date(timeIntervalSince1970: 1635946997)
        // America/New York (EST) - November 08, 2021 08:43:17 AM - exactly five 24-hour days after the last dismissed date.
        // But with daylight saving time in America/New York, it is still less than five days.
        let currentTime = Date(timeIntervalSince1970: 1636378997)
        let calendar: Calendar = {
            var calendar = Calendar(identifier: .gregorian)
            guard let timeZoneWithDaylightSavingTime = TimeZone(identifier: "America/New_York") else {
                XCTFail("Unexpected time zone.")
                return calendar
            }
            calendar.timeZone = timeZoneWithDaylightSavingTime
            return calendar
        }()

        let updateAction = AppSettingsAction.setJetpackBenefitsBannerLastDismissedTime(time: lastDismissedTime)
        subject?.onAction(updateAction)

        // When
        let isVisible: Bool = waitFor { promise in
            let action = AppSettingsAction.loadJetpackBenefitsBannerVisibility(currentTime: currentTime, calendar: calendar) { isVisible in
                promise(isVisible)
            }
            self.subject?.onAction(action)
        }

        // Then
        XCTAssertFalse(isVisible)
    }

    func test_loadJetpackBenefitsBannerVisibility_returns_false_after_setting_last_dismissed_date_less_than_five_days_ago() throws {
        // Given
        try fileStorage?.deleteFile(at: expectedGeneralAppSettingsFileURL)

        // GMT - Tuesday, November 23, 2021 1:25:24 PM
        let lastDismissedTime = Date(timeIntervalSince1970: 1637673924)
        // GMT - Sunday, November 28, 2021 1:25:23 PM - exactly 1 second less than five days after the last dismissed date without DST
        let currentTime = Date(timeIntervalSince1970: 1638105923)
        let calendar: Calendar = {
            var calendar = Calendar(identifier: .gregorian)
            guard let timeZoneWithoutDaylightSavingTime = TimeZone(identifier: "Asia/Taipei") else {
                XCTFail("Unexpected time zone.")
                return calendar
            }
            calendar.timeZone = timeZoneWithoutDaylightSavingTime
            return calendar
        }()

        let updateAction = AppSettingsAction.setJetpackBenefitsBannerLastDismissedTime(time: lastDismissedTime)
        subject?.onAction(updateAction)

        // When
        let isVisible: Bool = waitFor { promise in
            let action = AppSettingsAction.loadJetpackBenefitsBannerVisibility(currentTime: currentTime, calendar: calendar) { isVisible in
                promise(isVisible)
            }
            self.subject?.onAction(action)
        }

        // Then
        XCTAssertFalse(isVisible)
    }

    // MARK: - General Store Settings

    func test_setStoreID_stores_the_store_id_correctly() throws {
        // Given
        let siteID: Int64 = 1234

        let existingSettings = GeneralStoreSettingsBySite(storeSettingsBySite: [siteID: GeneralStoreSettings()])
        try fileStorage?.write(existingSettings, to: expectedGeneralStoreSettingsFileURL)

        // When
        let action = AppSettingsAction.setStoreID(siteID: siteID, id: "sample-store-uuid")
        subject?.onAction(action)

        // Then
        let savedSettings: GeneralStoreSettingsBySite = try XCTUnwrap(fileStorage?.data(for: expectedGeneralStoreSettingsFileURL))
        let settingsForSite = savedSettings.storeSettingsBySite[siteID]

        XCTAssertEqual(settingsForSite?.storeID, "sample-store-uuid")
    }

    func test_getStoreID_retrieves_the_saved_store_id() throws {
        // Given
        let siteID: Int64 = 1234
        let existingSettings = GeneralStoreSettingsBySite(storeSettingsBySite: [siteID: GeneralStoreSettings(storeID: "sample-store-uuid")])
        try fileStorage?.write(existingSettings, to: expectedGeneralStoreSettingsFileURL)

        // When
        let storeID: String? = waitFor { promise in
            let action = AppSettingsAction.getStoreID(siteID: siteID) { id in
                promise(id)
            }
            self.subject?.onAction(action)
        }

        // Then
        XCTAssertEqual(storeID, "sample-store-uuid")
    }

    func test_saving_isTelemetryAvailable_works_correctly() throws {
        // Given
        let siteID: Int64 = 1234
        let initialTime = Date(timeIntervalSince1970: 100)

        let existingSettings = GeneralStoreSettingsBySite(storeSettingsBySite: [siteID: GeneralStoreSettings(isTelemetryAvailable: true,
                                                                                                             telemetryLastReportedTime: initialTime)])
        try fileStorage?.write(existingSettings, to: expectedGeneralStoreSettingsFileURL)

        // When
        let action = AppSettingsAction.setTelemetryAvailability(siteID: siteID, isAvailable: false)
        subject?.onAction(action)

        // Then
        let savedSettings: GeneralStoreSettingsBySite = try XCTUnwrap(fileStorage?.data(for: expectedGeneralStoreSettingsFileURL))
        let settingsForSite = savedSettings.storeSettingsBySite[siteID]

        XCTAssertEqual(false, settingsForSite?.isTelemetryAvailable)

        // The other properties should be kept
        XCTAssertEqual(initialTime, settingsForSite?.telemetryLastReportedTime)
    }

    func test_saving_isTelemetryAvailable_works_correctly_when_the_settings_file_does_not_exist() throws {
        // Given
        let siteID: Int64 = 1234

        try fileStorage?.deleteFile(at: expectedGeneralStoreSettingsFileURL)

        // When
        let action = AppSettingsAction.setTelemetryAvailability(siteID: siteID, isAvailable: true)
        subject?.onAction(action)

        // Then
        let savedSettings: GeneralStoreSettingsBySite = try XCTUnwrap(fileStorage?.data(for: expectedGeneralStoreSettingsFileURL))
        let settingsForSite = savedSettings.storeSettingsBySite[siteID]

        XCTAssertEqual(true, settingsForSite?.isTelemetryAvailable)
    }

    func test_saving_telemetryLastReportedTime_works_correctly() throws {
        // Given
        let siteID: Int64 = 1234
        let initialTime = Date(timeIntervalSince1970: 100)
        let newTime = Date(timeIntervalSince1970: 500)

        let existingSettings = GeneralStoreSettingsBySite(storeSettingsBySite: [siteID: GeneralStoreSettings(isTelemetryAvailable: true,
                                                                                                             telemetryLastReportedTime: initialTime)])
        try fileStorage?.write(existingSettings, to: expectedGeneralStoreSettingsFileURL)

        // When
        let action = AppSettingsAction.setTelemetryLastReportedTime(siteID: siteID, time: newTime)
        subject?.onAction(action)

        // Then
        let savedSettings: GeneralStoreSettingsBySite = try XCTUnwrap(fileStorage?.data(for: expectedGeneralStoreSettingsFileURL))
        let settingsForSite = savedSettings.storeSettingsBySite[siteID]

        XCTAssertEqual(newTime, settingsForSite?.telemetryLastReportedTime)

        // The other properties should be kept
        XCTAssertEqual(true, settingsForSite?.isTelemetryAvailable)
    }

    func test_saving_telemetryLastReportedTime_works_correctly_when_the_settings_file_does_not_exist() throws {
        // Given
        let siteID: Int64 = 1234
        let newTime = Date(timeIntervalSince1970: 500)

        try fileStorage?.deleteFile(at: expectedGeneralStoreSettingsFileURL)

        // When
        let action = AppSettingsAction.setTelemetryLastReportedTime(siteID: siteID, time: newTime)
        subject?.onAction(action)

        // Then
        let savedSettings: GeneralStoreSettingsBySite = try XCTUnwrap(fileStorage?.data(for: expectedGeneralStoreSettingsFileURL))
        let settingsForSite = savedSettings.storeSettingsBySite[siteID]

        XCTAssertEqual(newTime, settingsForSite?.telemetryLastReportedTime)
    }

    func test_getTelemetryInfo_returns_correct_saved_data() throws {
        // Given
        let siteID: Int64 = 1234
        let initialTime = Date(timeIntervalSince1970: 100)

        let existingSettings = GeneralStoreSettingsBySite(storeSettingsBySite: [siteID: GeneralStoreSettings(isTelemetryAvailable: true,
                                                                                                             telemetryLastReportedTime: initialTime)])
        try fileStorage?.write(existingSettings, to: expectedGeneralStoreSettingsFileURL)

        // When
        let data: (isAvailable: Bool, telemetryLastReportedTime: Date?) = waitFor { promise in
            let action = AppSettingsAction.getTelemetryInfo(siteID: siteID) { isAvailable, telemetryLastReportedTime in
                promise((isAvailable, telemetryLastReportedTime))
            }
            self.subject?.onAction(action)
        }

        // Then
        XCTAssertTrue(data.isAvailable)
        XCTAssertEqual(initialTime, data.telemetryLastReportedTime)
    }

    func test_getTelemetryInfo_returns_correct_default_data() throws {
        // Given
        let siteID: Int64 = 1234
        try fileStorage?.deleteFile(at: expectedGeneralAppSettingsFileURL)

        // When
        let data: (isAvailable: Bool, telemetryLastReportedTime: Date?) = waitFor { promise in
            let action = AppSettingsAction.getTelemetryInfo(siteID: siteID) { isAvailable, telemetryLastReportedTime in
                promise((isAvailable, telemetryLastReportedTime))
            }
            self.subject?.onAction(action)
        }

        // Then
        XCTAssertFalse(data.isAvailable)
        XCTAssertNil(data.telemetryLastReportedTime)
    }

    func test_simplePaymentsToggleTaxes_returns_correct_default_data() throws {
        // Given
        let siteID: Int64 = 1234
        try fileStorage?.deleteFile(at: expectedGeneralAppSettingsFileURL)

        // When
        let result: Result<Bool, Error> = waitFor { promise in
            let action = AppSettingsAction.getSimplePaymentsTaxesToggleState(siteID: siteID) { result in
                promise(result)
            }
            self.subject?.onAction(action)
        }

        // Then
        XCTAssertFalse(try result.get())
    }

    func test_simplePaymentsToggleTaxes_returns_correct_saved_data() throws {
        // Given
        let siteID: Int64 = 1234

        let action = AppSettingsAction.setSimplePaymentsTaxesToggleState(siteID: siteID, isOn: true) { _ in }
        self.subject?.onAction(action)

        // When
        let result: Result<Bool, Error> = waitFor { promise in
            let action = AppSettingsAction.getSimplePaymentsTaxesToggleState(siteID: siteID) { result in
                promise(result)
            }
            self.subject?.onAction(action)
        }

        // Then
        XCTAssertTrue(try result.get())
    }

    func test_saving_preferredInPersonPaymentGateway_works_correctly() throws {
        // Given
        let siteID: Int64 = 1234
        let initialTime = Date(timeIntervalSince1970: 100)
        let preferredGateway = "woocommerce-payments"

        let existingSettings = GeneralStoreSettingsBySite(storeSettingsBySite: [siteID: GeneralStoreSettings(isTelemetryAvailable: true,
                                                                                                             telemetryLastReportedTime: initialTime)])
        try fileStorage?.write(existingSettings, to: expectedGeneralStoreSettingsFileURL)

        // When
        let action = AppSettingsAction.setPreferredInPersonPaymentGateway(siteID: siteID, gateway: preferredGateway)
        subject?.onAction(action)

        // Then
        let savedSettings: GeneralStoreSettingsBySite = try XCTUnwrap(fileStorage?.data(for: expectedGeneralStoreSettingsFileURL))
        let settingsForSite = savedSettings.storeSettingsBySite[siteID]

        XCTAssertEqual(preferredGateway, settingsForSite?.preferredInPersonPaymentGateway)

        // The other properties should be kept
        XCTAssertEqual(initialTime, settingsForSite?.telemetryLastReportedTime)
    }

    func test_saving_preferredInPersonPaymentGateway_works_correctly_when_the_settings_file_does_not_exist() throws {
        // Given
        let siteID: Int64 = 1234
        let preferredGateway = "woocommerce-payments"

        try fileStorage?.deleteFile(at: expectedGeneralStoreSettingsFileURL)

        // When
        let action = AppSettingsAction.setPreferredInPersonPaymentGateway(siteID: siteID, gateway: preferredGateway)
        subject?.onAction(action)

        // Then
        let savedSettings: GeneralStoreSettingsBySite = try XCTUnwrap(fileStorage?.data(for: expectedGeneralStoreSettingsFileURL))
        let settingsForSite = savedSettings.storeSettingsBySite[siteID]

        XCTAssertEqual(preferredGateway, settingsForSite?.preferredInPersonPaymentGateway)

    }

    func test_resetGeneralStoreSettings_resets_all_settings() throws {
        // Given
        let siteID: Int64 = 1234
        let initialTime = Date(timeIntervalSince1970: 100)

        let existingSettings = GeneralStoreSettingsBySite(storeSettingsBySite: [siteID: GeneralStoreSettings(isTelemetryAvailable: true,
                                                                                                             telemetryLastReportedTime: initialTime)])
        try fileStorage?.write(existingSettings, to: expectedGeneralStoreSettingsFileURL)

        // When
        let action = AppSettingsAction.resetGeneralStoreSettings
        subject?.onAction(action)

        // Then
        XCTAssertEqual(true, fileStorage?.deleteIsHit)
        let savedSettings: GeneralStoreSettingsBySite? = try fileStorage?.data(for: expectedGeneralStoreSettingsFileURL)
        XCTAssertNil(savedSettings)
    }
}

// MARK: - Feature Announcement Card Visibility

extension AppSettingsStoreTests {

    func test_setFeatureAnnouncementDismissed_for_campaign_when_remindAfterDays_is_nil_then_dismissal_is_stored_with_no_reminder_date() throws {
        // Given
        try fileStorage?.deleteFile(at: expectedGeneralStoreSettingsFileURL)
        // When
        let action = AppSettingsAction.setFeatureAnnouncementDismissed(campaign: .linkedProductsPromo, remindAfterDays: nil, onCompletion: nil)
        subject?.onAction(action)

        // Then
        let savedSettings: GeneralAppSettings? = try XCTUnwrap(fileStorage?.data(for: expectedGeneralAppSettingsFileURL))
        guard let savedSettings else {
            return XCTFail("Expected settings to be saved, but none were found")
        }
        let dismissedDate: Date = try XCTUnwrap(savedSettings.featureAnnouncementCampaignSettings[.linkedProductsPromo]?.dismissedDate)
        XCTAssert(Calendar.current.isDateInToday(dismissedDate))
        let remindAfterDate: Date? = savedSettings.featureAnnouncementCampaignSettings[.linkedProductsPromo]?.remindAfter
        XCTAssertNil(remindAfterDate)
    }

    func test_setFeatureAnnouncementDismissed_for_campaign_stores_current_date() throws {
        // Given
        let currentTime = Date()

        try fileStorage?.deleteFile(at: expectedGeneralStoreSettingsFileURL)

        // When
        let action = AppSettingsAction.setFeatureAnnouncementDismissed(campaign: .linkedProductsPromo, remindAfterDays: 0, onCompletion: nil)
        subject?.onAction(action)

        // Then
        let savedSettings: GeneralAppSettings = try XCTUnwrap(fileStorage?.data(for: expectedGeneralAppSettingsFileURL))

        let actualDismissDate = try XCTUnwrap(savedSettings.featureAnnouncementCampaignSettings[.linkedProductsPromo]?.dismissedDate)

        XCTAssert(Calendar.current.isDate(actualDismissDate, inSameDayAs: currentTime))
    }

    func test_setFeatureAnnouncementDismissed_when_remindAfterDays_is_two_weeks_then_stores_reminder_date_is_two_weeks() throws {
        // Given
        let remindAfterDays = 14
        let twoWeeksTime = Calendar.current.date(byAdding: .day, value: remindAfterDays, to: Date())!

        try fileStorage?.deleteFile(at: expectedGeneralStoreSettingsFileURL)

        // When
        let action = AppSettingsAction.setFeatureAnnouncementDismissed(campaign: .linkedProductsPromo, remindAfterDays: remindAfterDays, onCompletion: nil)
        subject?.onAction(action)

        // Then
        let savedSettings: GeneralAppSettings = try XCTUnwrap(fileStorage?.data(for: expectedGeneralAppSettingsFileURL))

        let actualRemindAfter = try XCTUnwrap(savedSettings.featureAnnouncementCampaignSettings[.linkedProductsPromo]?.remindAfter)

        XCTAssert(Calendar.current.isDate(actualRemindAfter, inSameDayAs: twoWeeksTime))
    }

    func test_setFeatureAnnouncementDismissed_when_remindAfterDays_is_seven_days_stores_reminder_then_date_saved_date_is_one_week() throws {
        // Given
        let remindAfterDays = 7
        let oneWeekTime = Calendar.current.date(byAdding: .day, value: remindAfterDays, to: Date())!

        try fileStorage?.deleteFile(at: expectedGeneralStoreSettingsFileURL)

        // When
        let action = AppSettingsAction.setFeatureAnnouncementDismissed(campaign: .linkedProductsPromo, remindAfterDays: remindAfterDays, onCompletion: nil)
        subject?.onAction(action)

        // Then
        let savedSettings: GeneralAppSettings = try XCTUnwrap(fileStorage?.data(for: expectedGeneralAppSettingsFileURL))

        let actualRemindAfter = try XCTUnwrap(savedSettings.featureAnnouncementCampaignSettings[.linkedProductsPromo]?.remindAfter)

        XCTAssert(Calendar.current.isDate(actualRemindAfter, inSameDayAs: oneWeekTime))
    }

    func test_setFeatureAnnouncementDismissed_with_another_campaign_previously_dismissed_keeps_values_for_both() throws {
        // Given
        try fileStorage?.deleteFile(at: expectedGeneralStoreSettingsFileURL)

        let currentTime = Date()

        let settings = createAppSettings(featureAnnouncementCampaignSettings: [.test: .init(dismissedDate: currentTime, remindAfter: nil)])
        try fileStorage?.write(settings, to: expectedGeneralAppSettingsFileURL)

        // When
        let action = AppSettingsAction.setFeatureAnnouncementDismissed(campaign: .linkedProductsPromo, remindAfterDays: 0, onCompletion: nil)
        subject?.onAction(action)

        // Then
        let savedSettings: GeneralAppSettings = try XCTUnwrap(fileStorage?.data(for: expectedGeneralAppSettingsFileURL))

        let actualDismissDate = try XCTUnwrap(savedSettings.featureAnnouncementCampaignSettings[.linkedProductsPromo]?.dismissedDate)

        XCTAssert(Calendar.current.isDate(actualDismissDate, inSameDayAs: currentTime))

        let otherCampaignDismissDate = try XCTUnwrap(savedSettings.featureAnnouncementCampaignSettings[.test]?.dismissedDate)

        assertEqual(currentTime, otherCampaignDismissDate)
    }

    func test_getFeatureAnnouncementVisibility_without_stored_setting_calls_completion_with_visibility_true() throws {
        // Given
        try fileStorage?.deleteFile(at: expectedGeneralAppSettingsFileURL)

        // When
        let result: Result<Bool, Error> = waitFor { promise in
            let action = AppSettingsAction.getFeatureAnnouncementVisibility(campaign: .linkedProductsPromo) { result in
                promise(result)
            }
            self.subject?.onAction(action)
        }

        // Then
        let isEnabled = try result.get()
        XCTAssertTrue(isEnabled)
    }

    func test_getFeatureAnnouncementVisibility_with_stored_dismissDate_and_no_remindAfter_calls_completion_with_visibility_false() throws {
        // Given
        try fileStorage?.deleteFile(at: expectedGeneralAppSettingsFileURL)
        let date = Date(timeIntervalSince1970: 100)

        let settings = createAppSettings(featureAnnouncementCampaignSettings: [.linkedProductsPromo: .init(dismissedDate: date, remindAfter: nil)])
        try fileStorage?.write(settings, to: expectedGeneralAppSettingsFileURL)

        // When
        let result: Result<Bool, Error> = waitFor { promise in
            let action = AppSettingsAction.getFeatureAnnouncementVisibility(campaign: .linkedProductsPromo) { result in
                promise(result)
            }
            self.subject?.onAction(action)
        }

        // Then
        let isEnabled = try result.get()
        XCTAssertFalse(isEnabled)
    }

    func test_getFeatureAnnouncementVisibility_with_stored_dismissDate_and_future_remindAfter_calls_completion_with_visibility_false() throws {
        // Given
        try fileStorage?.deleteFile(at: expectedGeneralAppSettingsFileURL)
        let dismissedDate = Date()
        let oneMinute = Calendar.current.date(byAdding: .minute, value: 1, to: dismissedDate)

        let settings = createAppSettings(featureAnnouncementCampaignSettings: [.linkedProductsPromo: .init(dismissedDate: dismissedDate,
                                                                                                           remindAfter: oneMinute)])
        try fileStorage?.write(settings, to: expectedGeneralAppSettingsFileURL)

        // When
        let result: Result<Bool, Error> = waitFor { promise in
            let action = AppSettingsAction.getFeatureAnnouncementVisibility(campaign: .linkedProductsPromo) { result in
                promise(result)
            }
            self.subject?.onAction(action)
        }

        // Then
        let isEnabled = try result.get()
        XCTAssertFalse(isEnabled)
    }

    func test_getFeatureAnnouncementVisibility_with_stored_dismissDate_and_past_remindAfter_calls_completion_with_visibility_true() throws {
        // Given
        try fileStorage?.deleteFile(at: expectedGeneralAppSettingsFileURL)
        let dismissedDate = Calendar.current.date(byAdding: .minute, value: -2, to: Date())!
        let oneMinuteAgo = Calendar.current.date(byAdding: .minute, value: -1, to: dismissedDate)

        let campaignSettings = FeatureAnnouncementCampaignSettings(
            dismissedDate: dismissedDate,
            remindAfter: oneMinuteAgo)
        let settings = createAppSettings(featureAnnouncementCampaignSettings: [.linkedProductsPromo: campaignSettings])
        try fileStorage?.write(settings, to: expectedGeneralAppSettingsFileURL)

        // When
        let result: Result<Bool, Error> = waitFor { promise in
            let action = AppSettingsAction.getFeatureAnnouncementVisibility(campaign: .linkedProductsPromo) { result in
                promise(result)
            }
            self.subject?.onAction(action)
        }

        // Then
        let isEnabled = try result.get()
        XCTAssertTrue(isEnabled)
    }

    func test_loadSiteHasAtLeastOneIPPTransactionFinished_when_nothing_is_saved_returns_false() throws {
        // Given
        try fileStorage?.deleteFile(at: expectedGeneralAppSettingsFileURL)

        // When
        let result: Bool = waitFor { promise in
            let action = AppSettingsAction.loadSiteHasAtLeastOneIPPTransactionFinished(siteID: 1) { result in
                promise(result)
            }
            self.subject?.onAction(action)
        }

        // Then
        XCTAssertFalse(result)
    }

    func test_loadSiteHasAtLeastOneIPPTransactionFinished_when_it_is_marked_using_legacy_code_for_a_different_site_returns_false() throws {
        // Given
        let siteIDA: Int64 = 1
        let siteIDB: Int64 = 2
        try fileStorage?.deleteFile(at: expectedGeneralAppSettingsFileURL)
        try generalAppSettings?.setValue([siteIDA], for: \.sitesWithAtLeastOneIPPTransactionFinished)

        // When
        let result: Bool = waitFor { promise in
            let action = AppSettingsAction.loadSiteHasAtLeastOneIPPTransactionFinished(siteID: siteIDB) { result in
                promise(result)
            }
            self.subject?.onAction(action)
        }

        // Then
        XCTAssertFalse(result)
    }

    func test_loadSiteHasAtLeastOneIPPTransactionFinished_when_it_is_marked_using_legacy_code_for_that_site_returns_true() throws {
        // Given
        let siteID: Int64 = 1
        try fileStorage?.deleteFile(at: expectedGeneralAppSettingsFileURL)
        try generalAppSettings?.setValue([siteID], for: \.sitesWithAtLeastOneIPPTransactionFinished)

        // When
        let result: Bool = waitFor { promise in
            let action = AppSettingsAction.loadSiteHasAtLeastOneIPPTransactionFinished(siteID: siteID) { result in
                promise(result)
            }
            self.subject?.onAction(action)
        }

        // Then
        XCTAssertTrue(result)
    }

    func test_loadSiteHasAtLeastOneIPPTransactionFinished_when_it_is_marked_for_a_different_site_returns_false() throws {
        // Given
        let siteIDA: Int64 = 1
        let siteIDB: Int64 = 2
        try fileStorage?.deleteFile(at: expectedGeneralAppSettingsFileURL)
        let action = AppSettingsAction.storeInPersonPaymentsTransactionIfFirst(siteID: siteIDA, cardReaderType: .other)
        subject?.onAction(action)

        // When
        let result: Bool = waitFor { promise in
            let action = AppSettingsAction.loadSiteHasAtLeastOneIPPTransactionFinished(siteID: siteIDB) { result in
                promise(result)
            }
            self.subject?.onAction(action)
        }

        // Then
        XCTAssertFalse(result)
    }

    func test_loadSiteHasAtLeastOneIPPTransactionFinished_when_it_is_marked_via_first_transactions_for_that_site_returns_true() throws {
        // Given
        let siteID: Int64 = 1
        try fileStorage?.deleteFile(at: expectedGeneralAppSettingsFileURL)
        let action = AppSettingsAction.storeInPersonPaymentsTransactionIfFirst(siteID: siteID, cardReaderType: .other)
        subject?.onAction(action)

        // When
        let result: Bool = waitFor { promise in
            let action = AppSettingsAction.loadSiteHasAtLeastOneIPPTransactionFinished(siteID: siteID) { result in
                promise(result)
            }
            self.subject?.onAction(action)
        }

        // Then
        XCTAssertTrue(result)
    }

    func test_given_no_data_has_been_stored_loadFirstInPersonPaymentsTransactionDate_returns_nil() throws {
        // Given
        try fileStorage?.deleteFile(at: expectedGeneralAppSettingsFileURL)

        // When
        let actualValue = waitFor { promise in
            let action = AppSettingsAction.loadFirstInPersonPaymentsTransactionDate(siteID: 1, cardReaderType: .appleBuiltIn) { maybeDate in
                promise(maybeDate)
            }
            self.subject?.onAction(action)
        }

        // Then
        XCTAssertNil(actualValue)
    }

    func test_given_a_date_was_previously_stored_for_the_site_and_reader_loadFirstInPersonPaymentsTransactionDate_returns_that_date() throws {
        // Given
        let siteID: Int64 = 1
        try fileStorage?.deleteFile(at: expectedGeneralAppSettingsFileURL)
        let updateAction = AppSettingsAction.storeInPersonPaymentsTransactionIfFirst(siteID: siteID, cardReaderType: .appleBuiltIn)
        subject?.onAction(updateAction)

        // When
        let actualValue = waitFor { promise in
            let action = AppSettingsAction.loadFirstInPersonPaymentsTransactionDate(siteID: siteID, cardReaderType: .appleBuiltIn) { maybeDate in
                promise(maybeDate)
            }
            self.subject?.onAction(action)
        }

        // Then
        let storedDate = try XCTUnwrap(actualValue)
        XCTAssertTrue(storedDate.timeIntervalSinceNow < 60)
    }

    func test_given_a_date_was_only_previously_stored_for_another_site_loadFirstInPersonPaymentsTransactionDate_returns_nil() throws {
        // Given
        try fileStorage?.deleteFile(at: expectedGeneralAppSettingsFileURL)
        let updateAction = AppSettingsAction.storeInPersonPaymentsTransactionIfFirst(siteID: 1, cardReaderType: .appleBuiltIn)
        subject?.onAction(updateAction)

        // When
        let actualValue = waitFor { promise in
            let action = AppSettingsAction.loadFirstInPersonPaymentsTransactionDate(siteID: 100, cardReaderType: .appleBuiltIn) { maybeDate in
                promise(maybeDate)
            }
            self.subject?.onAction(action)
        }

        // Then
        XCTAssertNil(actualValue)
    }

    func test_given_a_date_was_only_previously_stored_for_another_reader_loadFirstInPersonPaymentsTransactionDate_returns_nil() throws {
        // Given
        let siteID: Int64 = 1
        try fileStorage?.deleteFile(at: expectedGeneralAppSettingsFileURL)
        let updateAction = AppSettingsAction.storeInPersonPaymentsTransactionIfFirst(siteID: siteID, cardReaderType: .stripeM2)
        subject?.onAction(updateAction)

        // When
        let actualValue = waitFor { promise in
            let action = AppSettingsAction.loadFirstInPersonPaymentsTransactionDate(siteID: siteID, cardReaderType: .appleBuiltIn) { maybeDate in
                promise(maybeDate)
            }
            self.subject?.onAction(action)
        }

        // Then
        XCTAssertNil(actualValue)
    }

    func test_setSelectedTaxRateID_works_correctly() throws {
        // Given
        let siteID: Int64 = 1234
        let storedTaxRateID: Int64 = 4321

        let existingSettings = GeneralStoreSettingsBySite(storeSettingsBySite: [siteID: GeneralStoreSettings(selectedTaxRateID: 0)])
        try fileStorage?.write(existingSettings, to: expectedGeneralStoreSettingsFileURL)

        // When
        let action = AppSettingsAction.setSelectedTaxRateID(id: storedTaxRateID, siteID: siteID)
        subject?.onAction(action)

        // Then
        let savedSettings: GeneralStoreSettingsBySite = try XCTUnwrap(fileStorage?.data(for: expectedGeneralStoreSettingsFileURL))
        let settingsForSite = savedSettings.storeSettingsBySite[siteID]

        XCTAssertEqual(storedTaxRateID, settingsForSite?.selectedTaxRateID)
    }

    func test_setSelectedTaxRateID_when_nil_then_erases_the_value() throws {
        // Given
        let siteID: Int64 = 1234

        let existingSettings = GeneralStoreSettingsBySite(storeSettingsBySite: [siteID: GeneralStoreSettings(selectedTaxRateID: 34)])
        try fileStorage?.write(existingSettings, to: expectedGeneralStoreSettingsFileURL)

        // When
        let action = AppSettingsAction.setSelectedTaxRateID(id: nil, siteID: siteID)
        subject?.onAction(action)

        // Then
        let savedSettings: GeneralStoreSettingsBySite = try XCTUnwrap(fileStorage?.data(for: expectedGeneralStoreSettingsFileURL))
        let settingsForSite = savedSettings.storeSettingsBySite[siteID]

        XCTAssertNil(settingsForSite?.selectedTaxRateID)
    }

    func test_loadSelectedTaxRateID_works_correctly() throws {
        // Given
        let siteID: Int64 = 1234
        let storedTaxRateID: Int64 = 4321

        let existingSettings = GeneralStoreSettingsBySite(storeSettingsBySite: [siteID: GeneralStoreSettings(selectedTaxRateID: storedTaxRateID)])
        try fileStorage?.write(existingSettings, to: expectedGeneralStoreSettingsFileURL)

        // When
        var loadedTaxRateID: Int64?
        let action = AppSettingsAction.loadSelectedTaxRateID(siteID: siteID) { taxRateID in
            loadedTaxRateID = taxRateID
        }
        subject?.onAction(action)

        // Then
        XCTAssertEqual(loadedTaxRateID, storedTaxRateID)
    }

    func test_setAnalyticsHubCards_works_correctly() throws {
        // Given
        let analyticsCards = [
            AnalyticsCard(type: .revenue, enabled: true),
            AnalyticsCard(type: .orders, enabled: false),
            AnalyticsCard(type: .products, enabled: true),
            AnalyticsCard(type: .sessions, enabled: false)
        ]
        let existingSettings = GeneralStoreSettingsBySite(storeSettingsBySite: [TestConstants.siteID: GeneralStoreSettings()])
        try fileStorage?.write(existingSettings, to: expectedGeneralStoreSettingsFileURL)

        // When
        let action = AppSettingsAction.setAnalyticsHubCards(siteID: TestConstants.siteID, cards: analyticsCards)
        subject?.onAction(action)

        // Then
        let savedSettings: GeneralStoreSettingsBySite = try XCTUnwrap(fileStorage?.data(for: expectedGeneralStoreSettingsFileURL))
        let settingsForSite = savedSettings.storeSettingsBySite[TestConstants.siteID]

        assertEqual(analyticsCards, settingsForSite?.analyticsHubCards)
    }

    func test_loadAnalyticsHubCards_works_correctly() throws {
        // Given
        let storedAnalyticsCards = [
            AnalyticsCard(type: .revenue, enabled: true),
            AnalyticsCard(type: .orders, enabled: false),
            AnalyticsCard(type: .products, enabled: true),
            AnalyticsCard(type: .sessions, enabled: false)
        ]
        let storeSettings = GeneralStoreSettings(analyticsHubCards: storedAnalyticsCards)
        let existingSettings = GeneralStoreSettingsBySite(storeSettingsBySite: [TestConstants.siteID: storeSettings])
        try fileStorage?.write(existingSettings, to: expectedGeneralStoreSettingsFileURL)

        // When
        var loadedAnalyticsCards: [AnalyticsCard]?
        let action = AppSettingsAction.loadAnalyticsHubCards(siteID: TestConstants.siteID) { cards in
            loadedAnalyticsCards = cards
        }
        subject?.onAction(action)

        // Then
        assertEqual(storedAnalyticsCards, loadedAnalyticsCards)
    }

    func test_loadAnalyticsHubCards_returns_nil_when_no_cards_are_saved() throws {
        // Given
        let existingSettings = GeneralStoreSettingsBySite(storeSettingsBySite: [TestConstants.siteID: GeneralStoreSettings()])
        try fileStorage?.write(existingSettings, to: expectedGeneralStoreSettingsFileURL)

        // When
        var loadedAnalyticsCards: [AnalyticsCard]?
        let action = AppSettingsAction.loadAnalyticsHubCards(siteID: TestConstants.siteID) { cards in
            loadedAnalyticsCards = cards
        }
        subject?.onAction(action)

        // Then
        XCTAssertNil(loadedAnalyticsCards)
    }

    // MARK: - custom time range tab

    func test_setCustomStatsTimeRange_works_correctly() throws {
        // Given
        let siteID: Int64 = 1234

        let fromDate = Date(timeIntervalSince1970: 1677486077) // Feb 27, 2023
        let toDate = Date(timeIntervalSince1970: 1709022077) // Feb 27, 2024
        let customTimeRange = StatsTimeRangeV4.custom(from: fromDate, to: toDate)

        let existingSettings = GeneralStoreSettingsBySite(storeSettingsBySite: [siteID: GeneralStoreSettings()])
        try fileStorage?.write(existingSettings, to: expectedGeneralStoreSettingsFileURL)

        // When
        let action = AppSettingsAction.setCustomStatsTimeRange(siteID: siteID, timeRange: customTimeRange)
        subject?.onAction(action)

        // Then
        let savedSettings: GeneralStoreSettingsBySite = try XCTUnwrap(fileStorage?.data(for: expectedGeneralStoreSettingsFileURL))
        let settingsForSite = savedSettings.storeSettingsBySite[siteID]

        assertEqual(customTimeRange.rawValue, settingsForSite?.customStatsTimeRange)
    }

    func test_loadCustomStatsTimeRange_works_correctly() throws {
        // Given
        let siteID: Int64 = 1234

        let fromDate = Date(timeIntervalSince1970: 1677486077) // Feb 27, 2023
        let toDate = Date(timeIntervalSince1970: 1709022077) // Feb 27, 2024
        let customTimeRange = StatsTimeRangeV4.custom(from: fromDate, to: toDate)

        let storeSettings = GeneralStoreSettings(customStatsTimeRange: customTimeRange.rawValue)
        let existingSettings = GeneralStoreSettingsBySite(storeSettingsBySite: [siteID: storeSettings])
        try fileStorage?.write(existingSettings, to: expectedGeneralStoreSettingsFileURL)

        // When
        var loadedCustomTimeRange: StatsTimeRangeV4?
        let action = AppSettingsAction.loadCustomStatsTimeRange(siteID: siteID) { timeRange in
            loadedCustomTimeRange = timeRange
        }
        subject?.onAction(action)

        // Then
        assertEqual(customTimeRange, loadedCustomTimeRange)
    }

    func test_loadCustomStatsTimeRange_returns_nil_when_no_custom_range_is_saved() throws {
        // Given
        let siteID: Int64 = 1234
        let existingSettings = GeneralStoreSettingsBySite(storeSettingsBySite: [siteID: GeneralStoreSettings()])
        try fileStorage?.write(existingSettings, to: expectedGeneralStoreSettingsFileURL)

        // When
        var customTimeRange: StatsTimeRangeV4?
        let action = AppSettingsAction.loadCustomStatsTimeRange(siteID: siteID) { timeRange in
            customTimeRange = timeRange
        }
        subject?.onAction(action)

        // Then
        XCTAssertNil(customTimeRange)
    }

    // MARK: - dashboard cards
    func test_setDashboardCards_works_correctly() throws {
        // Given
        let dashboardCards = [
            DashboardCard(type: .onboarding, availability: .show, enabled: false),
            DashboardCard(type: .performance, availability: .show, enabled: true),
            DashboardCard(type: .topPerformers, availability: .show, enabled: true),
            DashboardCard(type: .blaze, availability: .show, enabled: true)
        ]
        let existingSettings = GeneralStoreSettingsBySite(storeSettingsBySite: [TestConstants.siteID: GeneralStoreSettings()])
        try fileStorage?.write(existingSettings, to: expectedGeneralStoreSettingsFileURL)

        // When
        let action = AppSettingsAction.setDashboardCards(siteID: TestConstants.siteID, cards: dashboardCards)
        subject?.onAction(action)

        // Then
        let savedSettings: GeneralStoreSettingsBySite = try XCTUnwrap(fileStorage?.data(for: expectedGeneralStoreSettingsFileURL))
        let settingsForSite = savedSettings.storeSettingsBySite[TestConstants.siteID]

        assertEqual(dashboardCards, settingsForSite?.dashboardCards)
    }

    func test_loadDashboardCards_works_correctly() throws {
        // Given
        let storedDashboardCards = [
            DashboardCard(type: .onboarding, availability: .show, enabled: false),
            DashboardCard(type: .performance, availability: .show, enabled: true),
            DashboardCard(type: .topPerformers, availability: .show, enabled: true),
            DashboardCard(type: .blaze, availability: .show, enabled: true)
        ]
        let storeSettings = GeneralStoreSettings(dashboardCards: storedDashboardCards)
        let existingSettings = GeneralStoreSettingsBySite(storeSettingsBySite: [TestConstants.siteID: storeSettings])
        try fileStorage?.write(existingSettings, to: expectedGeneralStoreSettingsFileURL)

        // When
        var loadedDashboardCards: [DashboardCard]?
        let action = AppSettingsAction.loadDashboardCards(siteID: TestConstants.siteID) { cards in
            loadedDashboardCards = cards
        }
        subject?.onAction(action)

        // Then
        assertEqual(storedDashboardCards, loadedDashboardCards)
    }

    func test_loadDashboardCards_returns_nil_when_no_cards_are_saved() throws {
        // Given
        let existingSettings = GeneralStoreSettingsBySite(storeSettingsBySite: [TestConstants.siteID: GeneralStoreSettings()])
        try fileStorage?.write(existingSettings, to: expectedGeneralStoreSettingsFileURL)

        // When
        var loadedDashboardCards: [DashboardCard]?
        let action = AppSettingsAction.loadDashboardCards(siteID: TestConstants.siteID) { cards in
            loadedDashboardCards = cards
        }
        subject?.onAction(action)

        // Then
        XCTAssertNil(loadedDashboardCards)
    }

    // MARK: - Last selected time range for Performance card

    func test_setLastSelectedPerformanceTimeRange_works_correctly() throws {
        // Given
        let timeRange = StatsTimeRangeV4.thisYear
        let existingSettings = GeneralStoreSettingsBySite(storeSettingsBySite: [TestConstants.siteID: GeneralStoreSettings()])
        try fileStorage?.write(existingSettings, to: expectedGeneralStoreSettingsFileURL)

        // When
        let action = AppSettingsAction.setLastSelectedPerformanceTimeRange(siteID: TestConstants.siteID, timeRange: timeRange)
        subject?.onAction(action)

        // Then
        let savedSettings: GeneralStoreSettingsBySite = try XCTUnwrap(fileStorage?.data(for: expectedGeneralStoreSettingsFileURL))
        let settingsForSite = savedSettings.storeSettingsBySite[TestConstants.siteID]

        assertEqual(timeRange.rawValue, settingsForSite?.lastSelectedPerformanceTimeRange)
    }

    func test_loadLastSelectedPerformanceTimeRange_works_correctly() throws {
        // Given
        let timeRange = StatsTimeRangeV4.thisYear
        let storeSettings = GeneralStoreSettings(lastSelectedPerformanceTimeRange: timeRange.rawValue)
        let existingSettings = GeneralStoreSettingsBySite(storeSettingsBySite: [TestConstants.siteID: storeSettings])
        try fileStorage?.write(existingSettings, to: expectedGeneralStoreSettingsFileURL)

        // When
        var loadedTimeRange: StatsTimeRangeV4?
        let action = AppSettingsAction.loadLastSelectedPerformanceTimeRange(siteID: TestConstants.siteID) { timeRange in
            loadedTimeRange = timeRange
        }
        subject?.onAction(action)

        // Then
        assertEqual(timeRange, loadedTimeRange)
    }

    func test_loadLastSelectedPerformanceTimeRange_returns_nil_when_no_data_was_saved() throws {
        // Given
        let existingSettings = GeneralStoreSettingsBySite(storeSettingsBySite: [TestConstants.siteID: GeneralStoreSettings()])
        try fileStorage?.write(existingSettings, to: expectedGeneralStoreSettingsFileURL)

        // When
        var loadedTimeRange: StatsTimeRangeV4?
        let action = AppSettingsAction.loadLastSelectedPerformanceTimeRange(siteID: TestConstants.siteID) { timeRange in
            loadedTimeRange = timeRange
        }
        subject?.onAction(action)

        // Then
        XCTAssertNil(loadedTimeRange)
    }

    // MARK: - Last selected time range for Top Performers card

    func test_setLastSelectedTopPerformersTimeRange_works_correctly() throws {
        // Given
        let timeRange = StatsTimeRangeV4.thisWeek
        let existingSettings = GeneralStoreSettingsBySite(storeSettingsBySite: [TestConstants.siteID: GeneralStoreSettings()])
        try fileStorage?.write(existingSettings, to: expectedGeneralStoreSettingsFileURL)

        // When
        let action = AppSettingsAction.setLastSelectedTopPerformersTimeRange(siteID: TestConstants.siteID, timeRange: timeRange)
        subject?.onAction(action)

        // Then
        let savedSettings: GeneralStoreSettingsBySite = try XCTUnwrap(fileStorage?.data(for: expectedGeneralStoreSettingsFileURL))
        let settingsForSite = savedSettings.storeSettingsBySite[TestConstants.siteID]

        assertEqual(timeRange.rawValue, settingsForSite?.lastSelectedTopPerformersTimeRange)
    }

    func test_loadLastSelectedTopPerformersTimeRange_works_correctly() throws {
        // Given
        let timeRange = StatsTimeRangeV4.thisWeek
        let storeSettings = GeneralStoreSettings(lastSelectedTopPerformersTimeRange: timeRange.rawValue)
        let existingSettings = GeneralStoreSettingsBySite(storeSettingsBySite: [TestConstants.siteID: storeSettings])
        try fileStorage?.write(existingSettings, to: expectedGeneralStoreSettingsFileURL)

        // When
        var loadedTimeRange: StatsTimeRangeV4?
        let action = AppSettingsAction.loadLastSelectedTopPerformersTimeRange(siteID: TestConstants.siteID) { timeRange in
            loadedTimeRange = timeRange
        }
        subject?.onAction(action)

        // Then
        assertEqual(timeRange, loadedTimeRange)
    }

    func test_loadLastSelectedTopPerformersTimeRange_returns_nil_when_no_data_was_saved() throws {
        // Given
        let existingSettings = GeneralStoreSettingsBySite(storeSettingsBySite: [TestConstants.siteID: GeneralStoreSettings()])
        try fileStorage?.write(existingSettings, to: expectedGeneralStoreSettingsFileURL)

        // When
        var loadedTimeRange: StatsTimeRangeV4?
        let action = AppSettingsAction.loadLastSelectedTopPerformersTimeRange(siteID: TestConstants.siteID) { timeRange in
            loadedTimeRange = timeRange
        }
        subject?.onAction(action)

        // Then
        XCTAssertNil(loadedTimeRange)
    }

    // MARK: - Last selected time range for Most active coupons card

    func test_setLastSelectedMostActiveCouponsTimeRange_works_correctly() throws {
        // Given
        let timeRange = StatsTimeRangeV4.thisMonth
        let existingSettings = GeneralStoreSettingsBySite(storeSettingsBySite: [TestConstants.siteID: GeneralStoreSettings()])
        try fileStorage?.write(existingSettings, to: expectedGeneralStoreSettingsFileURL)

        // When
        let action = AppSettingsAction.setLastSelectedMostActiveCouponsTimeRange(siteID: TestConstants.siteID, timeRange: timeRange)
        subject?.onAction(action)

        // Then
        let savedSettings: GeneralStoreSettingsBySite = try XCTUnwrap(fileStorage?.data(for: expectedGeneralStoreSettingsFileURL))
        let settingsForSite = savedSettings.storeSettingsBySite[TestConstants.siteID]

        assertEqual(timeRange.rawValue, settingsForSite?.lastSelectedMostActiveCouponsTimeRange)
    }

    func test_loadLastSelectedMostActiveCouponsTimeRange_works_correctly() throws {
        // Given
        let timeRange = StatsTimeRangeV4.thisMonth
        let storeSettings = GeneralStoreSettings(lastSelectedMostActiveCouponsTimeRange: timeRange.rawValue)
        let existingSettings = GeneralStoreSettingsBySite(storeSettingsBySite: [TestConstants.siteID: storeSettings])
        try fileStorage?.write(existingSettings, to: expectedGeneralStoreSettingsFileURL)

        // When
        var loadedTimeRange: StatsTimeRangeV4?
        let action = AppSettingsAction.loadLastSelectedMostActiveCouponsTimeRange(siteID: TestConstants.siteID) { timeRange in
            loadedTimeRange = timeRange
        }
        subject?.onAction(action)

        // Then
        assertEqual(timeRange, loadedTimeRange)
    }

    func test_loadLastSelectedMostActiveCouponsTimeRange_returns_nil_when_no_data_was_saved() throws {
        // Given
        let existingSettings = GeneralStoreSettingsBySite(storeSettingsBySite: [TestConstants.siteID: GeneralStoreSettings()])
        try fileStorage?.write(existingSettings, to: expectedGeneralStoreSettingsFileURL)

        // When
        var loadedTimeRange: StatsTimeRangeV4?
        let action = AppSettingsAction.loadLastSelectedMostActiveCouponsTimeRange(siteID: TestConstants.siteID) { timeRange in
            loadedTimeRange = timeRange
        }
        subject?.onAction(action)

        // Then
        XCTAssertNil(loadedTimeRange)
    }

    // MARK: - Last selected stock type for Stock dashboard card

    func test_setLastSelectedStockType_works_correctly() throws {
        // Given
        let stockType = "lowstock"
        let existingSettings = GeneralStoreSettingsBySite(storeSettingsBySite: [TestConstants.siteID: GeneralStoreSettings()])
        try fileStorage?.write(existingSettings, to: expectedGeneralStoreSettingsFileURL)

        // When
        let action = AppSettingsAction.setLastSelectedStockType(siteID: TestConstants.siteID, type: stockType)
        subject?.onAction(action)

        // Then
        let savedSettings: GeneralStoreSettingsBySite = try XCTUnwrap(fileStorage?.data(for: expectedGeneralStoreSettingsFileURL))
        let settingsForSite = savedSettings.storeSettingsBySite[TestConstants.siteID]

        assertEqual(stockType, settingsForSite?.lastSelectedStockType)
    }

    func test_loadLastSelectedStockType_works_correctly() throws {
        // Given
        let stockType = "lowstock"
        let storeSettings = GeneralStoreSettings(lastSelectedStockType: stockType)
        let existingSettings = GeneralStoreSettingsBySite(storeSettingsBySite: [TestConstants.siteID: storeSettings])
        try fileStorage?.write(existingSettings, to: expectedGeneralStoreSettingsFileURL)

        // When
        var loadedStockType: String?
        let action = AppSettingsAction.loadLastSelectedStockType(siteID: TestConstants.siteID) { type in
            loadedStockType = type
        }
        subject?.onAction(action)

        // Then
        assertEqual(stockType, loadedStockType)
    }

    func test_loadLastSelectedStockType_returns_nil_when_no_data_was_saved() throws {
        // Given
        let existingSettings = GeneralStoreSettingsBySite(storeSettingsBySite: [TestConstants.siteID: GeneralStoreSettings()])
        try fileStorage?.write(existingSettings, to: expectedGeneralStoreSettingsFileURL)

        // When
        var loadedStockType: String?
        let action = AppSettingsAction.loadLastSelectedStockType(siteID: TestConstants.siteID) { type in
            loadedStockType = type
        }
        subject?.onAction(action)

        // Then
        XCTAssertNil(loadedStockType)
    }

    // MARK: - Last selected order status for Most recent orders card

    func test_setLastSelectedOrderStatus_works_correctly() throws {
        // Given
        let status = "pending"
        let existingSettings = GeneralStoreSettingsBySite(storeSettingsBySite: [TestConstants.siteID: GeneralStoreSettings()])
        try fileStorage?.write(existingSettings, to: expectedGeneralStoreSettingsFileURL)

        // When
        let action = AppSettingsAction.setLastSelectedOrderStatus(siteID: TestConstants.siteID, status: status)
        subject?.onAction(action)

        // Then
        let savedSettings: GeneralStoreSettingsBySite = try XCTUnwrap(fileStorage?.data(for: expectedGeneralStoreSettingsFileURL))
        let settingsForSite = savedSettings.storeSettingsBySite[TestConstants.siteID]

        assertEqual(status, settingsForSite?.lastSelectedOrderStatus)
    }

    func test_loadLastSelectedOrderStatus_works_correctly() throws {
        // Given
        let status = "pending"
        let storeSettings = GeneralStoreSettings(lastSelectedOrderStatus: status)
        let existingSettings = GeneralStoreSettingsBySite(storeSettingsBySite: [TestConstants.siteID: storeSettings])
        try fileStorage?.write(existingSettings, to: expectedGeneralStoreSettingsFileURL)

        // When
        var loadedOrderStatus: String?
        let action = AppSettingsAction.loadLastSelectedOrderStatus(siteID: TestConstants.siteID) { status in
            loadedOrderStatus = status
        }
        subject?.onAction(action)

        // Then
        assertEqual(status, loadedOrderStatus)
    }

    func test_loadLastSelectedOrderStatus_returns_nil_when_no_data_was_saved() throws {
        // Given
        let existingSettings = GeneralStoreSettingsBySite(storeSettingsBySite: [TestConstants.siteID: GeneralStoreSettings()])
        try fileStorage?.write(existingSettings, to: expectedGeneralStoreSettingsFileURL)

        // When
        var loadedOrderStatus: String?
        let action = AppSettingsAction.loadLastSelectedOrderStatus(siteID: TestConstants.siteID) { status in
            loadedOrderStatus = status
        }
        subject?.onAction(action)

        // Then
        XCTAssertNil(loadedOrderStatus)
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
        let settings = GeneralAppSettings(
            installationDate: installationDate,
            feedbacks: [feedback.name: feedback],
            isViewAddOnsSwitchEnabled: false,
            isInAppPurchasesSwitchEnabled: false,
            isPointOfSaleEnabled: false,
            knownCardReaders: [],
            featureAnnouncementCampaignSettings: [:],
            sitesWithAtLeastOneIPPTransactionFinished: [],
            isEUShippingNoticeDismissed: false
        )
        return (settings, feedback)
    }

    func createAppSettings(featureAnnouncementCampaignSettings: [FeatureAnnouncementCampaign: FeatureAnnouncementCampaignSettings] = [:]) -> GeneralAppSettings {
        let settings = GeneralAppSettings(
            installationDate: Date(),
            feedbacks: [:],
            isViewAddOnsSwitchEnabled: false,
            isInAppPurchasesSwitchEnabled: false,
            isPointOfSaleEnabled: false,
            knownCardReaders: [],
            featureAnnouncementCampaignSettings: featureAnnouncementCampaignSettings,
            sitesWithAtLeastOneIPPTransactionFinished: [],
            isEUShippingNoticeDismissed: false
        )
        return settings
    }

    var expectedGeneralStoreSettingsFileURL: URL {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        return documents!.appendingPathComponent("general-store-settings.plist")
    }
}
