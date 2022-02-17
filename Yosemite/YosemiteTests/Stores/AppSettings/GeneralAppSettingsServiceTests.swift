import Combine
@testable import Yosemite
import Storage
import XCTest

final class GeneralAppSettingServiceTests: XCTestCase {
    /// Mock File Storage: Load a plist in the test bundle
    ///
    private var fileStorage: MockInMemoryStorage!

    /// Settings Service
    ///
    private var service: GeneralAppSettingsService!

    private var cancelables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        cancelables = Set()
        fileStorage = MockInMemoryStorage()
        service = GeneralAppSettingsService(fileStorage: fileStorage, fileURL: expectedGeneralAppSettingsFileURL)
    }

    override func tearDown() {
        fileStorage = nil
        service = nil
        cancelables = nil
        super.tearDown()
    }

    func test_service_can_initialize_settings() {
        // Setting file doesn't exist at first
        XCTAssertTrue(fileStorage.data.isEmpty)

        let settings = service.settings
        // Initial settings match defaults
        XCTAssertEqual(settings, GeneralAppSettings.default)

        // Setting file still doesn't exist until we update settings
        XCTAssertTrue(fileStorage.data.isEmpty)
    }

    func test_service_persists_changes_to_disk() throws {
        // Setting file doesn't exist at first
        XCTAssertTrue(fileStorage.data.isEmpty)

        let settings = service.settings.copy(installationDate: Date())
        try service.update(settings: settings)

        // File should exist after updating settings
        XCTAssertFalse(fileStorage.data.isEmpty)
    }

    func test_service_publishes_changes() throws {
        var changeCount = 0

        service
            .settingsPublisher
            .sink { _ in
                changeCount += 1
            }
            .store(in: &cancelables)

        // Publisher always emit the current value immediately upon subscription
        XCTAssertEqual(changeCount, 1)

        let settings = service.settings.copy(installationDate: Date())
        try service.update(settings: settings)

        // Publisher emits another change when we update a value
        XCTAssertEqual(changeCount, 2)
    }

    func test_service_does_not_publish_duplicate_values() throws {
        var changeCount = 0

        service
            .publisher(for: \.lastJetpackBenefitsBannerDismissedTime)
            .sink { _ in
                changeCount += 1
            }
            .store(in: &cancelables)

        // Publisher always emit the current value immediately upon subscription
        XCTAssertEqual(changeCount, 1)

        try service.update(Date(), for: \.installationDate)
        // Publisher shouldn't emit change if the specific key path hasn't changed
        XCTAssertEqual(changeCount, 1)
        try service.update(Date(), for: \.lastJetpackBenefitsBannerDismissedTime)

        // Publisher emits another change when we update the specific key path
        XCTAssertEqual(changeCount, 2)
    }

    func test_service_value_getter() throws {
        let date = Date(timeIntervalSince1970: 100)
        let settings = GeneralAppSettings.default
            .copy(installationDate: date)
        try service.update(settings: settings)

        XCTAssertEqual(service.value(for: \.installationDate), date)
    }

    func test_service_value_update() throws {
        let date = Date(timeIntervalSince1970: 100)
        try service.update(date, for: \.installationDate)

        XCTAssertEqual(service.value(for: \.installationDate), date)
    }

    func test_service_plucks_value() throws {
        let expected = FeedbackSettings(name: .general, status: .pending)
        let feedbacks: [FeedbackType: FeedbackSettings] = [
            expected.name: expected
        ]
        try service.update(feedbacks, for: \.feedbacks)

        let value = service.pluck(from: \.feedbacks, key: expected.name)
        XCTAssertEqual(value, expected)
    }

    func test_service_does_not_pluck_missing_value() throws {
        let missingType: FeedbackType = .productsVariations
        let expected = FeedbackSettings(name: .general, status: .pending)
        let feedbacks: [FeedbackType: FeedbackSettings] = [
            expected.name: expected
        ]
        try service.update(feedbacks, for: \.feedbacks)

        let value = service.pluck(from: \.feedbacks, key: missingType)
        XCTAssertNil(value)
    }

    func test_service_patches_existing_value() throws {
        let expected = FeedbackSettings(name: .general, status: .pending)
        let feedbacks: [FeedbackType: FeedbackSettings] = [
            expected.name: expected
        ]
        try service.update(feedbacks, for: \.feedbacks)

        let newFeedback = FeedbackSettings(name: .general, status: .dismissed)
        try service.patch(newFeedback, into: \.feedbacks, key: newFeedback.name)

        let value = service.value(for: \.feedbacks)
        XCTAssertEqual(value, [newFeedback.name: newFeedback])
    }

    func test_service_patches_new_value() throws {
        let existing = FeedbackSettings(name: .general, status: .pending)
        let feedbacks: [FeedbackType: FeedbackSettings] = [
            existing.name: existing
        ]
        try service.update(feedbacks, for: \.feedbacks)

        let newFeedback = FeedbackSettings(name: .productsVariations, status: .dismissed)
        try service.patch(newFeedback, into: \.feedbacks, key: newFeedback.name)

        let value = service.value(for: \.feedbacks)
        XCTAssertEqual(value[existing.name], existing)
        XCTAssertEqual(value[newFeedback.name], newFeedback)
    }
}

private extension GeneralAppSettingServiceTests {
    var expectedGeneralAppSettingsFileURL: URL {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        return documents!.appendingPathComponent("general-app-settings.plist")
    }
}
