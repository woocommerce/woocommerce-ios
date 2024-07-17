import XCTest

@testable import Yosemite
import struct Storage.GeneralAppSettings
import struct Storage.FeedbackSettings
import enum Storage.FeedbackType

private typealias InferenceError = InAppFeedbackCardVisibilityUseCase.InferenceError

/// Test cases for InAppFeedbackCardVisibilityUseCase.
///
final class InAppFeedbackCardVisibilityUseCaseTests: XCTestCase {

    private var dateFormatter: DateFormatter!
    private var calendar: Calendar!
    private var fileManager: MockFileManager!

    override func setUp() {
        super.setUp()
        dateFormatter = DateFormatter.Defaults.iso8601
        calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = dateFormatter.timeZone
        fileManager = MockFileManager()
    }

    override func tearDown() {
        fileManager = MockFileManager()
        calendar = nil
        dateFormatter = nil
        super.tearDown()
    }

    func test_shouldBeVisible_is_false_if_installationDate_is_less_than_90_days_ago() throws {
        // Given
        let installationDate = try date(from: "2020-08-08T00:00:00Z")
        let currentDate = try date(from: "2020-11-05T23:59:59Z")

        fileManager.whenRetrievingAttributesOfItem(atPath: try documentDirectoryURL().path, thenReturn: [:])

        let settings = createAppSetting(installationDate: installationDate, feedbackType: .general, feedbackStatus: .pending)
        let useCase = InAppFeedbackCardVisibilityUseCase(settings: settings, feedbackType: .general, fileManager: fileManager, calendar: calendar)

        // When
        let shouldBeVisible = try useCase.shouldBeVisible(currentDate: currentDate)

        // Then
        XCTAssertFalse(shouldBeVisible)
    }

    func test_shouldBeVisible_is_true_if_installationDate_is_more_than_or_equal_to_90_days_ago() throws {
        // Given
        let installationDate = try date(from: "2020-08-08T00:00:00Z")
        let currentDate = try date(from: "2020-11-06T00:00:00Z")

        fileManager.whenRetrievingAttributesOfItem(atPath: try documentDirectoryURL().path, thenReturn: [:])

        let settings = createAppSetting(installationDate: installationDate, feedbackType: .general, feedbackStatus: .pending)
        let useCase = InAppFeedbackCardVisibilityUseCase(settings: settings, feedbackType: .general, fileManager: fileManager, calendar: calendar)

        // When
        let shouldBeVisible = try useCase.shouldBeVisible(currentDate: currentDate)

        // Then
        XCTAssertTrue(shouldBeVisible)
    }

    func test_shouldBeVisible_is_false_if_lastFeedback_is_less_than_180_days_ago() throws {
        // Given
        let installationDate = try date(from: "2020-08-08T00:00:00Z")
        let lastFeedbackDate = try date(from: "2020-11-06T00:00:00Z")
        let currentDate = try date(from: "2021-05-04T23:59:59Z")

        fileManager.whenRetrievingAttributesOfItem(atPath: try documentDirectoryURL().path, thenReturn: [:])

        let settings = createAppSetting(installationDate: installationDate, feedbackType: .general, feedbackStatus: .given(lastFeedbackDate))
        let useCase = InAppFeedbackCardVisibilityUseCase(settings: settings, feedbackType: .general, fileManager: fileManager, calendar: calendar)

        // When
        let shouldBeVisible = try useCase.shouldBeVisible(currentDate: currentDate)

        // Then
        XCTAssertFalse(shouldBeVisible)
    }

    func test_shouldBeVisible_is_true_if_lastFeedback_is_more_than_or_equal_to_180_days_ago() throws {
        // Given
        let installationDate = try date(from: "2020-08-08T00:00:00Z")
        let lastFeedbackDate = try date(from: "2020-11-06T00:00:00Z")
        let currentDate = try date(from: "2021-05-05T00:00:00Z")

        fileManager.whenRetrievingAttributesOfItem(atPath: try documentDirectoryURL().path, thenReturn: [:])

        let settings = createAppSetting(installationDate: installationDate, feedbackType: .general, feedbackStatus: .given(lastFeedbackDate))
        let useCase = InAppFeedbackCardVisibilityUseCase(settings: settings, feedbackType: .general, fileManager: fileManager, calendar: calendar)

        // When
        let shouldBeVisible = try useCase.shouldBeVisible(currentDate: currentDate)

        // Then
        XCTAssertTrue(shouldBeVisible)
    }

    func test_shouldBeVisible_is_false_if_documentDir_creation_date_is_less_than_90_days_ago() throws {
        // Given
        let documentDirCreationDate = try date(from: "2020-08-08T00:00:00Z")
        let currentDate = try date(from: "2020-11-05T23:59:59Z")

        fileManager.whenRetrievingAttributesOfItem(atPath: try documentDirectoryURL().path,
                                                   thenReturn: [.creationDate: documentDirCreationDate])

        let settings = createAppSetting(installationDate: nil, feedbackType: .general, feedbackStatus: .pending)
        let useCase = InAppFeedbackCardVisibilityUseCase(settings: settings, feedbackType: .general, fileManager: fileManager, calendar: calendar)

        // When
        let shouldBeVisible = try useCase.shouldBeVisible(currentDate: currentDate)

        // Then
        XCTAssertFalse(shouldBeVisible)
    }

    func test_shouldBeVisible_is_true_if_documentDir_creation_date_is_more_than_or_equal_to_90_days_ago() throws {
        // Given
        let documentDirCreationDate = try date(from: "2020-08-08T00:00:00Z")
        // The installationDate is ignored because it is "later" than documentDirCreationDate
        let installationDate = try date(from: "2020-08-09T00:00:00Z")
        let currentDate = try date(from: "2020-11-06T00:00:00Z")

        fileManager.whenRetrievingAttributesOfItem(atPath: try documentDirectoryURL().path,
                                                   thenReturn: [.creationDate: documentDirCreationDate])

        let settings = createAppSetting(installationDate: installationDate, feedbackType: .general, feedbackStatus: .pending)
        let useCase = InAppFeedbackCardVisibilityUseCase(settings: settings, feedbackType: .general, fileManager: fileManager, calendar: calendar)

        // When
        let shouldBeVisible = try useCase.shouldBeVisible(currentDate: currentDate)

        // Then
        XCTAssertTrue(shouldBeVisible)
    }

    func test_shouldBeVisible_throws_if_the_installation_date_cannot_be_inferred() throws {
        // Given
        fileManager.whenRetrievingAttributesOfItem(atPath: try documentDirectoryURL().path, thenReturn: [:])

        let settings = createAppSetting(installationDate: nil, feedbackType: .general, feedbackStatus: .pending)
        let useCase = InAppFeedbackCardVisibilityUseCase(settings: settings, feedbackType: .general, fileManager: fileManager, calendar: calendar)

        // When
        var error: Error?
        XCTAssertThrowsError(try useCase.shouldBeVisible()) {
            error = $0
        }

        // Then
        XCTAssertEqual(error as? InferenceError, .failedToInferInstallationDate)
    }

    func test_orderFormShippingLines_shouldBeVisible_is_true_if_feedback_status_is_pending() throws {
        // Given
        let lastFeedbackDate = try date(from: "2020-11-06T00:00:00Z")
        let currentDate = try date(from: "2020-11-12T23:59:59Z")

        fileManager.whenRetrievingAttributesOfItem(atPath: try documentDirectoryURL().path, thenReturn: [:])

        let settings = createAppSetting(installationDate: nil, feedbackType: .orderFormShippingLines, feedbackStatus: .pending)
        let useCase = InAppFeedbackCardVisibilityUseCase(settings: settings, feedbackType: .orderFormShippingLines, fileManager: fileManager, calendar: calendar)

        // When
        let shouldBeVisible = try useCase.shouldBeVisible(currentDate: currentDate)

        // Then
        XCTAssertTrue(shouldBeVisible)
    }

    func test_orderFormShippingLines_shouldBeVisible_is_false_if_feedback_status_is_dismissed() throws {
        // Given
        let lastFeedbackDate = try date(from: "2020-11-06T00:00:00Z")
        let currentDate = try date(from: "2020-11-12T23:59:59Z")

        fileManager.whenRetrievingAttributesOfItem(atPath: try documentDirectoryURL().path, thenReturn: [:])

        let settings = createAppSetting(installationDate: nil, feedbackType: .orderFormShippingLines, feedbackStatus: .dismissed)
        let useCase = InAppFeedbackCardVisibilityUseCase(settings: settings, feedbackType: .orderFormShippingLines, fileManager: fileManager, calendar: calendar)

        // When
        let shouldBeVisible = try useCase.shouldBeVisible(currentDate: currentDate)

        // Then
        XCTAssertFalse(shouldBeVisible)
    }

    func test_orderFormShippingLines_shouldBeVisible_is_false_if_lastFeedback_is_less_than_7_days_ago() throws {
        // Given
        let lastFeedbackDate = try date(from: "2020-11-06T00:00:00Z")
        let currentDate = try date(from: "2020-11-12T23:59:59Z")

        fileManager.whenRetrievingAttributesOfItem(atPath: try documentDirectoryURL().path, thenReturn: [:])

        let settings = createAppSetting(installationDate: nil, feedbackType: .orderFormShippingLines, feedbackStatus: .given(lastFeedbackDate))
        let useCase = InAppFeedbackCardVisibilityUseCase(settings: settings, feedbackType: .orderFormShippingLines, fileManager: fileManager, calendar: calendar)

        // When
        let shouldBeVisible = try useCase.shouldBeVisible(currentDate: currentDate)

        // Then
        XCTAssertFalse(shouldBeVisible)
    }

    func test_orderFormShippingLines_shouldBeVisible_is_true_if_lastFeedback_is_more_than_or_equal_to_7_days_ago() throws {
        // Given
        let lastFeedbackDate = try date(from: "2020-11-06T00:00:00Z")
        let currentDate = try date(from: "2020-11-13T00:00:00Z")

        fileManager.whenRetrievingAttributesOfItem(atPath: try documentDirectoryURL().path, thenReturn: [:])

        let settings = createAppSetting(installationDate: nil, feedbackType: .orderFormShippingLines, feedbackStatus: .given(lastFeedbackDate))
        let useCase = InAppFeedbackCardVisibilityUseCase(settings: settings, feedbackType: .orderFormShippingLines, fileManager: fileManager, calendar: calendar)

        // When
        let shouldBeVisible = try useCase.shouldBeVisible(currentDate: currentDate)

        // Then
        XCTAssertTrue(shouldBeVisible)
    }
}

// MARK: - Utils

private extension InAppFeedbackCardVisibilityUseCaseTests {
    func date(from iso8601Date: String) throws -> Date {
        try XCTUnwrap(dateFormatter.date(from: iso8601Date))
    }

    func documentDirectoryURL() throws -> URL {
        try XCTUnwrap(FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last)
    }

    func createAppSetting(installationDate: Date?, feedbackType: FeedbackType, feedbackStatus: FeedbackSettings.Status) -> GeneralAppSettings {
        let feedback = FeedbackSettings(name: feedbackType, status: feedbackStatus)
        let settings = GeneralAppSettings(
            installationDate: installationDate,
            feedbacks: [feedback.name: feedback],
            isViewAddOnsSwitchEnabled: false,
            isInAppPurchasesSwitchEnabled: false,
            isPointOfSaleEnabled: false,
            knownCardReaders: [],
            featureAnnouncementCampaignSettings: [:],
            sitesWithAtLeastOneIPPTransactionFinished: [],
            isEUShippingNoticeDismissed: false)
        return settings
    }
}
