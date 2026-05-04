import XCTest
import YosemiteTestHelpers
@testable import Yosemite
@testable import Storage


/// Mock constants
///
private struct TestConstants {
    static let fileURL = Bundle.module
        .url(forResource: "shipment-provider", withExtension: "plist")
    static let customFileURL = Bundle.module
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

    /// Mock Site Specific App Settings Store Methods

    private var mockSiteSpecificAppSettingsStoreMethods: MockSiteSpecificAppSettingsStoreMethods!

    override func setUp() {
        super.setUp()
        dispatcher = Dispatcher()
        storageManager = MockStorageManager()
        fileStorage = MockInMemoryStorage()
        generalAppSettings = GeneralAppSettingsStorage(fileStorage: fileStorage!)
        mockSiteSpecificAppSettingsStoreMethods = MockSiteSpecificAppSettingsStoreMethods()
        mockSiteSpecificAppSettingsStoreMethods.currentSiteID = TestConstants.siteID
        subject = AppSettingsStore(dispatcher: dispatcher!,
                                   storageManager: storageManager!,
                                   fileStorage: fileStorage!,
                                   generalAppSettings: generalAppSettings!,
                                   siteSpecificAppSettingsStoreMethods: mockSiteSpecificAppSettingsStoreMethods)
        subject?.selectedProvidersURL = TestConstants.fileURL!
        subject?.customSelectedProvidersURL = TestConstants.customFileURL!
    }

    override func tearDown() {
        dispatcher = nil
        storageManager = nil
        fileStorage = nil
        generalAppSettings = nil
        subject = nil
        mockSiteSpecificAppSettingsStoreMethods = nil
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

        // Use a unique temp directory for isolation
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(UUID().uuidString + "-general-app-settings.plist")
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true, attributes: nil)

        // Create our own infrastructure so we can inject `PListFileStorage` and custom fileURL.
        let fileStorage = PListFileStorage()
        let storageManager = MockStorageManager()
        let generalAppSettings = GeneralAppSettingsStorage(fileStorage: fileStorage, fileURL: fileURL)
        let dispatcher = Dispatcher()
        let store = AppSettingsStore(dispatcher: dispatcher, storageManager: storageManager, fileStorage: fileStorage, generalAppSettings: generalAppSettings)

        // Make sure the file does not exist
        if FileManager.default.fileExists(atPath: fileURL.path) {
            try? fileStorage.deleteFile(at: fileURL)
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

        let savedSettings: GeneralAppSettings = try XCTUnwrap(fileStorage.data(for: fileURL))
        XCTAssertEqual(date, savedSettings.installationDate)

        // Clean up
        try? fileStorage.deleteFile(at: fileURL)
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
        let storeID = "test-store-id"

        // When
        let action = AppSettingsAction.setStoreID(siteID: TestConstants.siteID, id: storeID)
        subject?.onAction(action)

        // Then
        XCTAssertTrue(mockSiteSpecificAppSettingsStoreMethods.setStoreIDCalled)
        XCTAssertEqual(mockSiteSpecificAppSettingsStoreMethods.spySetStoreIDSiteID, TestConstants.siteID)
        XCTAssertEqual(mockSiteSpecificAppSettingsStoreMethods.spySetStoreID, storeID)
    }

    func test_getStoreID_retrieves_the_saved_store_id() throws {
        // Given
        let expectedStoreID = "test-store-id"
        mockSiteSpecificAppSettingsStoreMethods.mockStoreID = expectedStoreID

        // When
        let retrievedStoreID: String? = waitFor { promise in
            let action = AppSettingsAction.getStoreID(siteID: TestConstants.siteID) { id in
                promise(id)
            }
            self.subject?.onAction(action)
        }

        // Then
        XCTAssertTrue(mockSiteSpecificAppSettingsStoreMethods.getStoreIDCalled)
        XCTAssertEqual(mockSiteSpecificAppSettingsStoreMethods.spyGetStoreIDSiteID, TestConstants.siteID)
        XCTAssertEqual(retrievedStoreID, expectedStoreID)
    }

    func test_saving_isTelemetryAvailable_works_correctly() throws {
        // Given
        let initialTime = Date(timeIntervalSince1970: 100)

        mockSiteSpecificAppSettingsStoreMethods.storeSettings = GeneralStoreSettings(isTelemetryAvailable: true,
                                                                                     telemetryLastReportedTime: initialTime)

        // When
        let action = AppSettingsAction.setTelemetryAvailability(siteID: TestConstants.siteID, isAvailable: false)
        subject?.onAction(action)

        // Then
        let settingsForSite = mockSiteSpecificAppSettingsStoreMethods.storeSettings

        XCTAssertEqual(false, settingsForSite.isTelemetryAvailable)

        // The other properties should be kept
        XCTAssertEqual(initialTime, settingsForSite.telemetryLastReportedTime)
    }

    func test_saving_telemetryLastReportedTime_works_correctly() throws {
        // Given
        let initialTime = Date(timeIntervalSince1970: 100)
        let newTime = Date(timeIntervalSince1970: 500)

        mockSiteSpecificAppSettingsStoreMethods.storeSettings = GeneralStoreSettings(isTelemetryAvailable: true,
                                                                                     telemetryLastReportedTime: initialTime)

        // When
        let action = AppSettingsAction.setTelemetryLastReportedTime(siteID: TestConstants.siteID, time: newTime)
        subject?.onAction(action)

        // Then
        let settingsForSite = mockSiteSpecificAppSettingsStoreMethods.storeSettings

        XCTAssertEqual(newTime, settingsForSite.telemetryLastReportedTime)

        // The other properties should be kept
        XCTAssertEqual(true, settingsForSite.isTelemetryAvailable)
    }

    func test_getTelemetryInfo_returns_correct_saved_data() throws {
        // Given
        let initialTime = Date(timeIntervalSince1970: 100)

        mockSiteSpecificAppSettingsStoreMethods.storeSettings = GeneralStoreSettings(isTelemetryAvailable: true,
                                                                                     telemetryLastReportedTime: initialTime)

        // When
        let data: (isAvailable: Bool, telemetryLastReportedTime: Date?) = waitFor { promise in
            let action = AppSettingsAction.getTelemetryInfo(siteID: TestConstants.siteID) { isAvailable, telemetryLastReportedTime in
                promise((isAvailable, telemetryLastReportedTime))
            }
            self.subject?.onAction(action)
        }

        // Then
        XCTAssertTrue(data.isAvailable)
        XCTAssertEqual(initialTime, data.telemetryLastReportedTime)
    }

    func test_getTelemetryInfo_returns_correct_default_data() throws {
        // When
        let data: (isAvailable: Bool, telemetryLastReportedTime: Date?) = waitFor { promise in
            let action = AppSettingsAction.getTelemetryInfo(siteID: TestConstants.siteID) { isAvailable, telemetryLastReportedTime in
                promise((isAvailable, telemetryLastReportedTime))
            }
            self.subject?.onAction(action)
        }

        // Then
        XCTAssertFalse(data.isAvailable)
        XCTAssertNil(data.telemetryLastReportedTime)
    }

    func test_simplePaymentsToggleTaxes_returns_correct_default_data() throws {
        // When
        let result: Result<Bool, Error> = waitFor { promise in
            let action = AppSettingsAction.getSimplePaymentsTaxesToggleState(siteID: TestConstants.siteID) { result in
                promise(result)
            }
            self.subject?.onAction(action)
        }

        // Then
        XCTAssertFalse(try result.get())
    }

    func test_simplePaymentsToggleTaxes_returns_correct_saved_data() throws {
        // Given
        let action = AppSettingsAction.setSimplePaymentsTaxesToggleState(siteID: TestConstants.siteID, isOn: true) { _ in }
        self.subject?.onAction(action)

        // When
        let result: Result<Bool, Error> = waitFor { promise in
            let action = AppSettingsAction.getSimplePaymentsTaxesToggleState(siteID: TestConstants.siteID) { result in
                promise(result)
            }
            self.subject?.onAction(action)
        }

        // Then
        XCTAssertTrue(try result.get())
    }

    func test_saving_preferredInPersonPaymentGateway_works_correctly() throws {
        // Given
        let initialTime = Date(timeIntervalSince1970: 100)
        let preferredGateway = "woocommerce-payments"

        mockSiteSpecificAppSettingsStoreMethods.storeSettings = GeneralStoreSettings(isTelemetryAvailable: true,
                                                                                     telemetryLastReportedTime: initialTime)

        // When
        let action = AppSettingsAction.setPreferredInPersonPaymentGateway(siteID: TestConstants.siteID, gateway: preferredGateway)
        subject?.onAction(action)

        // Then
        let settingsForSite = mockSiteSpecificAppSettingsStoreMethods.storeSettings

        XCTAssertEqual(preferredGateway, settingsForSite.preferredInPersonPaymentGateway)

        // The other properties should be kept
        XCTAssertEqual(initialTime, settingsForSite.telemetryLastReportedTime)
    }

    func test_saving_preferredInPersonPaymentGateway_works_correctly_when_the_settings_file_does_not_exist() throws {
        // Given
        let preferredGateway = "woocommerce-payments"

        // When
        let action = AppSettingsAction.setPreferredInPersonPaymentGateway(siteID: TestConstants.siteID, gateway: preferredGateway)
        subject?.onAction(action)

        // Then
        let settingsForSite = mockSiteSpecificAppSettingsStoreMethods.storeSettings

        XCTAssertEqual(preferredGateway, settingsForSite.preferredInPersonPaymentGateway)
    }

    func test_resetGeneralStoreSettings_resets_all_settings() throws {
        // When
        let action = AppSettingsAction.resetGeneralStoreSettings
        subject?.onAction(action)

        // Then
        XCTAssertTrue(mockSiteSpecificAppSettingsStoreMethods.resetStoreSettingsCalled)
    }
}

// MARK: - Feature Announcement Card Visibility

extension AppSettingsStoreTests {

    func test_setFeatureAnnouncementDismissed_for_campaign_when_remindAfterDays_is_nil_then_dismissal_is_stored_with_no_reminder_date() throws {
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
        mockSiteSpecificAppSettingsStoreMethods.currentSiteID = siteIDB
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
        let action = AppSettingsAction.storeInPersonPaymentsTransactionIfFirst(siteID: TestConstants.siteID, cardReaderType: .other)
        subject?.onAction(action)

        // When
        let result: Bool = waitFor { promise in
            let action = AppSettingsAction.loadSiteHasAtLeastOneIPPTransactionFinished(siteID: TestConstants.siteID) { result in
                promise(result)
            }
            self.subject?.onAction(action)
        }

        // Then
        XCTAssertTrue(result)
    }

    func test_given_no_data_has_been_stored_loadFirstInPersonPaymentsTransactionDate_returns_nil() throws {
        // When
        let actualValue = waitFor { promise in
            let action = AppSettingsAction.loadFirstInPersonPaymentsTransactionDate(siteID: TestConstants.siteID, cardReaderType: .tapToPay) { maybeDate in
                promise(maybeDate)
            }
            self.subject?.onAction(action)
        }

        // Then
        XCTAssertNil(actualValue)
    }

    func test_given_a_date_was_previously_stored_for_the_site_and_reader_loadFirstInPersonPaymentsTransactionDate_returns_that_date() throws {
        // Given
        let updateAction = AppSettingsAction.storeInPersonPaymentsTransactionIfFirst(siteID: TestConstants.siteID, cardReaderType: .tapToPay)
        subject?.onAction(updateAction)

        // When
        let actualValue = waitFor { promise in
            let action = AppSettingsAction.loadFirstInPersonPaymentsTransactionDate(siteID: TestConstants.siteID, cardReaderType: .tapToPay) { maybeDate in
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
        let updateAction = AppSettingsAction.storeInPersonPaymentsTransactionIfFirst(siteID: 1, cardReaderType: .tapToPay)
        subject?.onAction(updateAction)

        // When
        let actualValue = waitFor { promise in
            let action = AppSettingsAction.loadFirstInPersonPaymentsTransactionDate(siteID: TestConstants.siteID, cardReaderType: .tapToPay) { maybeDate in
                promise(maybeDate)
            }
            self.subject?.onAction(action)
        }

        // Then
        XCTAssertNil(actualValue)
    }

    func test_given_a_date_was_only_previously_stored_for_another_reader_loadFirstInPersonPaymentsTransactionDate_returns_nil() throws {
        // Given
        let updateAction = AppSettingsAction.storeInPersonPaymentsTransactionIfFirst(siteID: TestConstants.siteID, cardReaderType: .stripeM2)
        subject?.onAction(updateAction)

        // When
        let actualValue = waitFor { promise in
            let action = AppSettingsAction.loadFirstInPersonPaymentsTransactionDate(siteID: TestConstants.siteID, cardReaderType: .tapToPay) { maybeDate in
                promise(maybeDate)
            }
            self.subject?.onAction(action)
        }

        // Then
        XCTAssertNil(actualValue)
    }

    func test_setSelectedTaxRateID_works_correctly() throws {
        // Given
        let storedTaxRateID: Int64 = 4321

        mockSiteSpecificAppSettingsStoreMethods.storeSettings = GeneralStoreSettings(selectedTaxRateID: 0)

        // When
        let action = AppSettingsAction.setSelectedTaxRateID(id: storedTaxRateID, siteID: TestConstants.siteID)
        subject?.onAction(action)

        // Then
        let settingsForSite = mockSiteSpecificAppSettingsStoreMethods.storeSettings

        XCTAssertEqual(storedTaxRateID, settingsForSite.selectedTaxRateID)
    }

    func test_setSelectedTaxRateID_when_nil_then_erases_the_value() throws {
        // Given
        mockSiteSpecificAppSettingsStoreMethods.storeSettings = GeneralStoreSettings(selectedTaxRateID: 34)

        // When
        let action = AppSettingsAction.setSelectedTaxRateID(id: nil, siteID: TestConstants.siteID)
        subject?.onAction(action)

        // Then
        let settingsForSite = mockSiteSpecificAppSettingsStoreMethods.storeSettings

        XCTAssertNil(settingsForSite.selectedTaxRateID)
    }

    func test_loadSelectedTaxRateID_works_correctly() throws {
        // Given
        let storedTaxRateID: Int64 = 4321

        mockSiteSpecificAppSettingsStoreMethods.storeSettings = GeneralStoreSettings(selectedTaxRateID: storedTaxRateID)

        // When
        var loadedTaxRateID: Int64?
        let action = AppSettingsAction.loadSelectedTaxRateID(siteID: TestConstants.siteID) { taxRateID in
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
        mockSiteSpecificAppSettingsStoreMethods.storeSettings = GeneralStoreSettings()

        // When
        let action = AppSettingsAction.setAnalyticsHubCards(siteID: TestConstants.siteID, cards: analyticsCards)
        subject?.onAction(action)

        // Then
        let settingsForSite = mockSiteSpecificAppSettingsStoreMethods.storeSettings

        assertEqual(analyticsCards, settingsForSite.analyticsHubCards)
    }

    func test_loadAnalyticsHubCards_works_correctly() throws {
        // Given
        let storedAnalyticsCards = [
            AnalyticsCard(type: .revenue, enabled: true),
            AnalyticsCard(type: .orders, enabled: false),
            AnalyticsCard(type: .products, enabled: true),
            AnalyticsCard(type: .sessions, enabled: false)
        ]
        mockSiteSpecificAppSettingsStoreMethods.storeSettings = GeneralStoreSettings(analyticsHubCards: storedAnalyticsCards)

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
        mockSiteSpecificAppSettingsStoreMethods.storeSettings = GeneralStoreSettings()

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
        let fromDate = Date(timeIntervalSince1970: 1677486077) // Feb 27, 2023
        let toDate = Date(timeIntervalSince1970: 1709022077) // Feb 27, 2024
        let customTimeRange = StatsTimeRangeV4.custom(from: fromDate, to: toDate)

        mockSiteSpecificAppSettingsStoreMethods.storeSettings = GeneralStoreSettings()

        // When
        let action = AppSettingsAction.setCustomStatsTimeRange(siteID: TestConstants.siteID, timeRange: customTimeRange)
        subject?.onAction(action)

        // Then
        let settingsForSite = mockSiteSpecificAppSettingsStoreMethods.storeSettings

        assertEqual(customTimeRange.rawValue, settingsForSite.customStatsTimeRange)
    }

    func test_loadCustomStatsTimeRange_works_correctly() throws {
        // Given
        let fromDate = Date(timeIntervalSince1970: 1677486077) // Feb 27, 2023
        let toDate = Date(timeIntervalSince1970: 1709022077) // Feb 27, 2024
        let customTimeRange = StatsTimeRangeV4.custom(from: fromDate, to: toDate)

        mockSiteSpecificAppSettingsStoreMethods.storeSettings = GeneralStoreSettings(customStatsTimeRange: customTimeRange.rawValue)

        // When
        var loadedCustomTimeRange: StatsTimeRangeV4?
        let action = AppSettingsAction.loadCustomStatsTimeRange(siteID: TestConstants.siteID) { timeRange in
            loadedCustomTimeRange = timeRange
        }
        subject?.onAction(action)

        // Then
        assertEqual(customTimeRange, loadedCustomTimeRange)
    }

    func test_loadCustomStatsTimeRange_returns_nil_when_no_custom_range_is_saved() throws {
        // Given
        mockSiteSpecificAppSettingsStoreMethods.storeSettings = GeneralStoreSettings()

        // When
        var customTimeRange: StatsTimeRangeV4?
        let action = AppSettingsAction.loadCustomStatsTimeRange(siteID: TestConstants.siteID) { timeRange in
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
        mockSiteSpecificAppSettingsStoreMethods.storeSettings = GeneralStoreSettings()

        // When
        let action = AppSettingsAction.setDashboardCards(siteID: TestConstants.siteID, cards: dashboardCards)
        subject?.onAction(action)

        // Then
        let settingsForSite = mockSiteSpecificAppSettingsStoreMethods.storeSettings

        assertEqual(dashboardCards, settingsForSite.dashboardCards)
    }

    func test_loadDashboardCards_works_correctly() throws {
        // Given
        let storedDashboardCards = [
            DashboardCard(type: .onboarding, availability: .show, enabled: false),
            DashboardCard(type: .performance, availability: .show, enabled: true),
            DashboardCard(type: .topPerformers, availability: .show, enabled: true),
            DashboardCard(type: .blaze, availability: .show, enabled: true)
        ]
        mockSiteSpecificAppSettingsStoreMethods.storeSettings = GeneralStoreSettings(dashboardCards: storedDashboardCards)

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
        mockSiteSpecificAppSettingsStoreMethods.storeSettings = GeneralStoreSettings()

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
        mockSiteSpecificAppSettingsStoreMethods.storeSettings = GeneralStoreSettings()

        // When
        let action = AppSettingsAction.setLastSelectedPerformanceTimeRange(siteID: TestConstants.siteID, timeRange: timeRange)
        subject?.onAction(action)

        // Then
        let settingsForSite = mockSiteSpecificAppSettingsStoreMethods.storeSettings

        assertEqual(timeRange.rawValue, settingsForSite.lastSelectedPerformanceTimeRange)
    }

    func test_loadLastSelectedPerformanceTimeRange_works_correctly() throws {
        // Given
        let timeRange = StatsTimeRangeV4.thisYear
        mockSiteSpecificAppSettingsStoreMethods.storeSettings = GeneralStoreSettings(lastSelectedPerformanceTimeRange: timeRange.rawValue)

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
        mockSiteSpecificAppSettingsStoreMethods.storeSettings = GeneralStoreSettings()

        // When
        var loadedTimeRange: StatsTimeRangeV4?
        let action = AppSettingsAction.loadLastSelectedPerformanceTimeRange(siteID: TestConstants.siteID) { timeRange in
            loadedTimeRange = timeRange
        }
        subject?.onAction(action)

        // Then
        XCTAssertNil(loadedTimeRange)
    }

    // MARK: - Last selected revenue stats type for Performance card

    func test_setLastSelectedDashboardRevenueStatsType_works_correctly() throws {
        // Given
        mockSiteSpecificAppSettingsStoreMethods.storeSettings = GeneralStoreSettings()

        // When
        let action = AppSettingsAction.setLastSelectedDashboardRevenueStatsType(siteID: TestConstants.siteID,
                                                                                revenueType: .net)
        subject?.onAction(action)

        // Then
        let settingsForSite = mockSiteSpecificAppSettingsStoreMethods.storeSettings
        assertEqual(DashboardRevenueStatsType.net.rawValue, settingsForSite.lastSelectedDashboardRevenueStatsType)
    }

    func test_loadLastSelectedDashboardRevenueStatsType_returns_persisted_value() throws {
        // Given
        mockSiteSpecificAppSettingsStoreMethods.storeSettings =
        GeneralStoreSettings(lastSelectedDashboardRevenueStatsType: DashboardRevenueStatsType.gross.rawValue)

        // When
        var loadedRevenueType: DashboardRevenueStatsType?
        let action = AppSettingsAction.loadLastSelectedDashboardRevenueStatsType(siteID: TestConstants.siteID) { revenueType in
            loadedRevenueType = revenueType
        }
        subject?.onAction(action)

        // Then
        assertEqual(DashboardRevenueStatsType.gross, loadedRevenueType)
    }

    func test_loadLastSelectedDashboardRevenueStatsType_returns_nil_when_no_data_was_saved() throws {
        // Given
        mockSiteSpecificAppSettingsStoreMethods.storeSettings = GeneralStoreSettings()

        // When
        var loadedRevenueType: DashboardRevenueStatsType?
        let action = AppSettingsAction.loadLastSelectedDashboardRevenueStatsType(siteID: TestConstants.siteID) { revenueType in
            loadedRevenueType = revenueType
        }
        subject?.onAction(action)

        // Then
        XCTAssertNil(loadedRevenueType)
    }

    // MARK: - Last selected time range for Top Performers card

    func test_setLastSelectedTopPerformersTimeRange_works_correctly() throws {
        // Given
        let timeRange = StatsTimeRangeV4.thisWeek
        mockSiteSpecificAppSettingsStoreMethods.storeSettings = GeneralStoreSettings()

        // When
        let action = AppSettingsAction.setLastSelectedTopPerformersTimeRange(siteID: TestConstants.siteID, timeRange: timeRange)
        subject?.onAction(action)

        // Then
        let settingsForSite = mockSiteSpecificAppSettingsStoreMethods.storeSettings

        assertEqual(timeRange.rawValue, settingsForSite.lastSelectedTopPerformersTimeRange)
    }

    func test_loadLastSelectedTopPerformersTimeRange_works_correctly() throws {
        // Given
        let timeRange = StatsTimeRangeV4.thisWeek
        mockSiteSpecificAppSettingsStoreMethods.storeSettings = GeneralStoreSettings(lastSelectedTopPerformersTimeRange: timeRange.rawValue)

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
        mockSiteSpecificAppSettingsStoreMethods.storeSettings = GeneralStoreSettings()

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
        mockSiteSpecificAppSettingsStoreMethods.storeSettings = GeneralStoreSettings()

        // When
        let action = AppSettingsAction.setLastSelectedMostActiveCouponsTimeRange(siteID: TestConstants.siteID, timeRange: timeRange)
        subject?.onAction(action)

        // Then
        let settingsForSite = mockSiteSpecificAppSettingsStoreMethods.storeSettings

        assertEqual(timeRange.rawValue, settingsForSite.lastSelectedMostActiveCouponsTimeRange)
    }

    func test_loadLastSelectedMostActiveCouponsTimeRange_works_correctly() throws {
        // Given
        let timeRange = StatsTimeRangeV4.thisMonth
        mockSiteSpecificAppSettingsStoreMethods.storeSettings = GeneralStoreSettings(lastSelectedMostActiveCouponsTimeRange: timeRange.rawValue)

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
        mockSiteSpecificAppSettingsStoreMethods.storeSettings = GeneralStoreSettings()

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
        mockSiteSpecificAppSettingsStoreMethods.storeSettings = GeneralStoreSettings()

        // When
        let action = AppSettingsAction.setLastSelectedStockType(siteID: TestConstants.siteID, type: stockType)
        subject?.onAction(action)

        // Then
        let settingsForSite = mockSiteSpecificAppSettingsStoreMethods.storeSettings

        assertEqual(stockType, settingsForSite.lastSelectedStockType)
    }

    func test_loadLastSelectedStockType_works_correctly() throws {
        // Given
        let stockType = "lowstock"
        mockSiteSpecificAppSettingsStoreMethods.storeSettings = GeneralStoreSettings(lastSelectedStockType: stockType)

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
        mockSiteSpecificAppSettingsStoreMethods.storeSettings = GeneralStoreSettings()

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
        mockSiteSpecificAppSettingsStoreMethods.storeSettings = GeneralStoreSettings()

        // When
        let action = AppSettingsAction.setLastSelectedOrderStatus(siteID: TestConstants.siteID, status: status)
        subject?.onAction(action)

        // Then
        let settingsForSite = mockSiteSpecificAppSettingsStoreMethods.storeSettings

        assertEqual(status, settingsForSite.lastSelectedOrderStatus)
    }

    func test_loadLastSelectedOrderStatus_works_correctly() throws {
        // Given
        let status = "pending"
        mockSiteSpecificAppSettingsStoreMethods.storeSettings = GeneralStoreSettings(lastSelectedOrderStatus: status)

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
        mockSiteSpecificAppSettingsStoreMethods.storeSettings = GeneralStoreSettings()

        // When
        var loadedOrderStatus: String?
        let action = AppSettingsAction.loadLastSelectedOrderStatus(siteID: TestConstants.siteID) { status in
            loadedOrderStatus = status
        }
        subject?.onAction(action)

        // Then
        XCTAssertNil(loadedOrderStatus)
    }

    // MARK: - Point of Sale Survey Notification

    func test_getPOSSurveyPotentialMerchantNotificationScheduled_returns_false_on_new_generalAppSettings() throws {
        // Given
        try fileStorage?.deleteFile(at: expectedGeneralAppSettingsFileURL)

        // When
        let result: Bool = waitFor { promise in
            let action = AppSettingsAction.getPOSSurveyPotentialMerchantNotificationScheduled { isScheduled in
                promise(isScheduled)
            }
            self.subject?.onAction(action)
        }

        // Then
        XCTAssertFalse(result)
    }

    func test_getPOSSurveyPotentialMerchantNotificationScheduled_returns_true_after_setting_as_scheduled() throws {
        // Given
        try fileStorage?.deleteFile(at: expectedGeneralAppSettingsFileURL)
        let setAction = AppSettingsAction.setPOSSurveyPotentialMerchantNotificationScheduled { _ in }
        subject?.onAction(setAction)

        // When
        let result: Bool = waitFor { promise in
            let action = AppSettingsAction.getPOSSurveyPotentialMerchantNotificationScheduled { isScheduled in
                promise(isScheduled)
            }
            self.subject?.onAction(action)
        }

        // Then
        XCTAssertTrue(result)
    }

    func test_setPOSSurveyPotentialMerchantNotificationScheduled_stores_value_correctly() throws {
        // Given
        try fileStorage?.deleteFile(at: expectedGeneralAppSettingsFileURL)

        // When
        var result: Result<Void, Error>?
        let action = AppSettingsAction.setPOSSurveyPotentialMerchantNotificationScheduled { aResult in
            result = aResult
        }
        subject?.onAction(action)

        // Then
        XCTAssertTrue(try XCTUnwrap(result).isSuccess)

        let savedSettings: GeneralAppSettings = try XCTUnwrap(fileStorage?.data(for: expectedGeneralAppSettingsFileURL))
        XCTAssertTrue(savedSettings.isPOSSurveyPotentialMerchantNotificationScheduled)
    }

    func test_getPOSSurveyCurrentMerchantNotificationScheduled_returns_false_on_new_generalAppSettings() throws {
        // Given
        try fileStorage?.deleteFile(at: expectedGeneralAppSettingsFileURL)

        // When
        let result: Bool = waitFor { promise in
            let action = AppSettingsAction.getPOSSurveyCurrentMerchantNotificationScheduled { isScheduled in
                promise(isScheduled)
            }
            self.subject?.onAction(action)
        }

        // Then
        XCTAssertFalse(result)
    }

    func test_getPOSSurveyCurrentMerchantNotificationScheduled_returns_true_after_setting_as_scheduled() throws {
        // Given
        try fileStorage?.deleteFile(at: expectedGeneralAppSettingsFileURL)
        let setAction = AppSettingsAction.setPOSSurveyCurrentMerchantNotificationScheduled { _ in }
        subject?.onAction(setAction)

        // When
        let result: Bool = waitFor { promise in
            let action = AppSettingsAction.getPOSSurveyCurrentMerchantNotificationScheduled { isScheduled in
                promise(isScheduled)
            }
            self.subject?.onAction(action)
        }

        // Then
        XCTAssertTrue(result)
    }

    func test_setPOSSurveyCurrentMerchantNotificationScheduled_stores_value_correctly() throws {
        // Given
        try fileStorage?.deleteFile(at: expectedGeneralAppSettingsFileURL)

        // When
        var result: Result<Void, Error>?
        let action = AppSettingsAction.setPOSSurveyCurrentMerchantNotificationScheduled { aResult in
            result = aResult
        }
        subject?.onAction(action)

        // Then
        XCTAssertTrue(try XCTUnwrap(result).isSuccess)

        let savedSettings: GeneralAppSettings = try XCTUnwrap(fileStorage?.data(for: expectedGeneralAppSettingsFileURL))
        XCTAssertTrue(savedSettings.isPOSSurveyCurrentMerchantNotificationScheduled)
    }

    func test_getHasPOSBeenOpenedAtLeastOnce_returns_false_on_new_generalAppSettings() throws {
        // Given
        try fileStorage?.deleteFile(at: expectedGeneralAppSettingsFileURL)

        // When
        let result: Bool = waitFor { promise in
            let action = AppSettingsAction.getHasPOSBeenOpenedAtLeastOnce { hasOpened in
                promise(hasOpened)
            }
            self.subject?.onAction(action)
        }

        // Then
        XCTAssertFalse(result)
    }

    func test_getHasPOSBeenOpenedAtLeastOnce_returns_true_after_setting() throws {
        // Given
        try fileStorage?.deleteFile(at: expectedGeneralAppSettingsFileURL)
        let setAction = AppSettingsAction.setHasPOSBeenOpenedAtLeastOnce { _ in }
        subject?.onAction(setAction)

        // When
        let result: Bool = waitFor { promise in
            let action = AppSettingsAction.getHasPOSBeenOpenedAtLeastOnce { hasOpened in
                promise(hasOpened)
            }
            self.subject?.onAction(action)
        }

        // Then
        XCTAssertTrue(result)
    }

    func test_setHasPOSBeenOpenedAtLeastOnce_stores_value_correctly() throws {
        // Given
        try fileStorage?.deleteFile(at: expectedGeneralAppSettingsFileURL)

        // When
        var result: Result<Void, Error>?
        let action = AppSettingsAction.setHasPOSBeenOpenedAtLeastOnce { aResult in
            result = aResult
        }
        subject?.onAction(action)

        // Then
        XCTAssertTrue(try XCTUnwrap(result).isSuccess)

        let savedSettings: GeneralAppSettings = try XCTUnwrap(fileStorage?.data(for: expectedGeneralAppSettingsFileURL))
        XCTAssertTrue(savedSettings.hasPOSBeenOpenedAtLeastOnce)
    }

    func test_resetPOSSurveyNotificationScheduled_resets_all_flags_to_false() throws {
        // Given
        try fileStorage?.deleteFile(at: expectedGeneralAppSettingsFileURL)

        // 1. Set all to true
        let setPotentialAction = AppSettingsAction.setPOSSurveyPotentialMerchantNotificationScheduled { _ in }
        subject?.onAction(setPotentialAction)
        let setCurrentAction = AppSettingsAction.setPOSSurveyCurrentMerchantNotificationScheduled { _ in }
        subject?.onAction(setCurrentAction)
        let setPOSOpenedAction = AppSettingsAction.setHasPOSBeenOpenedAtLeastOnce { _ in }
        subject?.onAction(setPOSOpenedAction)

        // 2. Verify all are true
        let checkPotentialBeforeReset: Bool = waitFor { promise in
            let action = AppSettingsAction.getPOSSurveyPotentialMerchantNotificationScheduled { isScheduled in
                promise(isScheduled)
            }
            self.subject?.onAction(action)
        }
        XCTAssertTrue(checkPotentialBeforeReset)

        let checkCurrentBeforeReset: Bool = waitFor { promise in
            let action = AppSettingsAction.getPOSSurveyCurrentMerchantNotificationScheduled { isScheduled in
                promise(isScheduled)
            }
            self.subject?.onAction(action)
        }
        XCTAssertTrue(checkCurrentBeforeReset)

        let checkPOSOpenedBeforeReset: Bool = waitFor { promise in
            let action = AppSettingsAction.getHasPOSBeenOpenedAtLeastOnce { hasOpened in
                promise(hasOpened)
            }
            self.subject?.onAction(action)
        }
        XCTAssertTrue(checkPOSOpenedBeforeReset)

        // When - 3. Reset all
        var resetResult: Result<Void, Error>?
        let resetAction = AppSettingsAction.resetPOSSurveyNotificationScheduled { aResult in
            resetResult = aResult
        }
        subject?.onAction(resetAction)

        // Then - 4. Verify all are false
        XCTAssertTrue(try XCTUnwrap(resetResult).isSuccess)

        let checkPotentialAfterReset: Bool = waitFor { promise in
            let action = AppSettingsAction.getPOSSurveyPotentialMerchantNotificationScheduled { isScheduled in
                promise(isScheduled)
            }
            self.subject?.onAction(action)
        }
        XCTAssertFalse(checkPotentialAfterReset)

        let checkCurrentAfterReset: Bool = waitFor { promise in
            let action = AppSettingsAction.getPOSSurveyCurrentMerchantNotificationScheduled { isScheduled in
                promise(isScheduled)
            }
            self.subject?.onAction(action)
        }
        XCTAssertFalse(checkCurrentAfterReset)

        let checkPOSOpenedAfterReset: Bool = waitFor { promise in
            let action = AppSettingsAction.getHasPOSBeenOpenedAtLeastOnce { hasOpened in
                promise(hasOpened)
            }
            self.subject?.onAction(action)
        }
        XCTAssertFalse(checkPOSOpenedAfterReset)
    }

    // MARK: - POS Local Catalog Cellular Data Tests

    func test_getPOSLocalCatalogCellularDataAllowed_returns_false_by_default() throws {
        // When
        let isAllowed: Bool = waitFor { promise in
            let action = AppSettingsAction.getPOSLocalCatalogCellularDataAllowed(siteID: TestConstants.siteID) { isAllowed in
                promise(isAllowed)
            }
            self.subject?.onAction(action)
        }

        // Then
        XCTAssertFalse(isAllowed)
    }

    func test_getPOSLocalCatalogCellularDataAllowed_returns_saved_value() throws {
        // Given
        mockSiteSpecificAppSettingsStoreMethods.mockPOSLocalCatalogCellularDataAllowed = true

        // When
        let isAllowed: Bool = waitFor { promise in
            let action = AppSettingsAction.getPOSLocalCatalogCellularDataAllowed(siteID: TestConstants.siteID) { isAllowed in
                promise(isAllowed)
            }
            self.subject?.onAction(action)
        }

        // Then
        XCTAssertTrue(mockSiteSpecificAppSettingsStoreMethods.getPOSLocalCatalogCellularDataAllowedCalled)
        XCTAssertTrue(isAllowed)
    }

    func test_setPOSLocalCatalogCellularDataAllowed_saves_value_successfully() throws {
        // When
        waitFor { promise in
            let action = AppSettingsAction.setPOSLocalCatalogCellularDataAllowed(siteID: TestConstants.siteID, allowed: true) {
                promise(())
            }
            self.subject?.onAction(action)
        }

        // Then
        XCTAssertTrue(mockSiteSpecificAppSettingsStoreMethods.setPOSLocalCatalogCellularDataAllowedCalled)
        XCTAssertEqual(mockSiteSpecificAppSettingsStoreMethods.mockPOSLocalCatalogCellularDataAllowed, true)
    }

    func test_setPOSLocalCatalogCellularDataAllowed_can_set_false() throws {
        // Given
        mockSiteSpecificAppSettingsStoreMethods.mockPOSLocalCatalogCellularDataAllowed = true

        // When
        waitFor { promise in
            let action = AppSettingsAction.setPOSLocalCatalogCellularDataAllowed(siteID: TestConstants.siteID, allowed: false) {
                promise(())
            }
            self.subject?.onAction(action)
        }

        // Then
        XCTAssertTrue(mockSiteSpecificAppSettingsStoreMethods.setPOSLocalCatalogCellularDataAllowedCalled)
        XCTAssertEqual(mockSiteSpecificAppSettingsStoreMethods.mockPOSLocalCatalogCellularDataAllowed, false)
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
            isApplicationPasswordsSwitchEnabled: false,
            isPOSLocalCatalogSwitchEnabled: false,
            knownCardReaders: [],
            featureAnnouncementCampaignSettings: [:],
            sitesWithAtLeastOneIPPTransactionFinished: [],
            isEUShippingNoticeDismissed: false,
            isCustomFieldsTopBannerDismissed: false,
            isPOSSurveyPotentialMerchantNotificationScheduled: false,
            isPOSSurveyCurrentMerchantNotificationScheduled: false,
            hasPOSBeenOpenedAtLeastOnce: false
        )
        return (settings, feedback)
    }

    func createAppSettings(featureAnnouncementCampaignSettings: [FeatureAnnouncementCampaign: FeatureAnnouncementCampaignSettings] = [:]) -> GeneralAppSettings {
        let settings = GeneralAppSettings(
            installationDate: Date(),
            feedbacks: [:],
            isViewAddOnsSwitchEnabled: false,
            isApplicationPasswordsSwitchEnabled: false,
            isPOSLocalCatalogSwitchEnabled: false,
            knownCardReaders: [],
            featureAnnouncementCampaignSettings: featureAnnouncementCampaignSettings,
            sitesWithAtLeastOneIPPTransactionFinished: [],
            isEUShippingNoticeDismissed: false,
            isCustomFieldsTopBannerDismissed: false,
            isPOSSurveyPotentialMerchantNotificationScheduled: false,
            isPOSSurveyCurrentMerchantNotificationScheduled: false,
            hasPOSBeenOpenedAtLeastOnce: false
        )
        return settings
    }
}
