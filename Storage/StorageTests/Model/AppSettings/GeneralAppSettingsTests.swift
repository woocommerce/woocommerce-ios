import XCTest
@testable import Storage

final class GeneralAppSettingsTests: XCTestCase {

    func test_it_returns_the_correct_status_of_a_stored_feedback() {
        // Given
        let feedback = FeedbackSettings(name: .general, status: .dismissed)
        let settings = createGeneralAppSettings(feedbacks: [.general: feedback])

        // When
        let loadedStatus = settings.feedbackStatus(of: .general)

        // Then
        XCTAssertEqual(feedback.status, loadedStatus)
    }

    func test_it_returns_pending_status_of_a_non_stored_feedback() {
        // Given
        let settings = createGeneralAppSettings()

        // When
        let loadedStatus = settings.feedbackStatus(of: .general)

        // Then
        XCTAssertEqual(loadedStatus, .pending)
    }

    func test_it_replaces_feedback_when_feedback_exists() {
        // Given
        let existingFeedback = FeedbackSettings(name: .general, status: .dismissed)
        let settings = createGeneralAppSettings(feedbacks: [.general: existingFeedback])

        // When
        let newFeedback = FeedbackSettings(name: .general, status: .given(Date()))
        let newSettings = settings.replacing(feedback: newFeedback)

        // Then
        XCTAssertEqual(newSettings.feedbacks[.general], newFeedback)
    }

    func test_it_adds_new_feedback_when_replacing_empty_feedback_store() {
        // Given
        let settings = createGeneralAppSettings()

        // When
        let newFeedback = FeedbackSettings(name: .general, status: .given(Date()))
        let newSettings = settings.replacing(feedback: newFeedback)

        // Then
        XCTAssertEqual(newSettings.feedbacks[.general], newFeedback)
    }

    func test_updating_properties_to_generalAppSettings_does_not_breaks_decoding() throws {
        // Given
        let installationDate = Date(timeIntervalSince1970: 1630314000) // Mon Aug 30 2021 09:00:00 UTC+0000
        let jetpackBannerDismissedDate = Date(timeIntervalSince1970: 1631523600) // Mon Sep 13 2021 09:00:00 UTC+0000
        let feedbackSettings = [FeedbackType.general: FeedbackSettings(name: .general, status: .pending)]
        let readers = ["aaaaa", "bbbbbb"]
        let eligibilityInfo = EligibilityErrorInfo(name: "user", roles: ["admin"])
        let previousSettings = GeneralAppSettings(installationDate: installationDate,
                                                  feedbacks: feedbackSettings,
                                                  isViewAddOnsSwitchEnabled: true,
                                                  isOrderCreationSwitchEnabled: true,
                                                  knownCardReaders: readers,
                                                  lastEligibilityErrorInfo: eligibilityInfo,
                                                  lastJetpackBenefitsBannerDismissedTime: jetpackBannerDismissedDate)

        let previousEncodedSettings = try JSONEncoder().encode(previousSettings)
        var previousSettingsJson = try JSONSerialization.jsonObject(with: previousEncodedSettings, options: .allowFragments) as? [String: Any]

        // When
        previousSettingsJson?.removeValue(forKey: "isViewAddOnsSwitchEnabled")
        let newEncodedSettings = try JSONSerialization.data(withJSONObject: previousSettingsJson as Any, options: .fragmentsAllowed)
        let newSettings = try JSONDecoder().decode(GeneralAppSettings.self, from: newEncodedSettings)

        // Then
        assertEqual(newSettings.installationDate, installationDate)
        assertEqual(newSettings.feedbacks, feedbackSettings)
        assertEqual(newSettings.knownCardReaders, readers)
        assertEqual(newSettings.lastEligibilityErrorInfo, eligibilityInfo)
        assertEqual(newSettings.isViewAddOnsSwitchEnabled, false)
        assertEqual(newSettings.isOrderCreationSwitchEnabled, true)
        assertEqual(newSettings.lastJetpackBenefitsBannerDismissedTime, jetpackBannerDismissedDate)
    }
}

private extension GeneralAppSettingsTests {
    func createGeneralAppSettings(installationDate: Date? = nil,
                                  feedbacks: [FeedbackType: FeedbackSettings] = [:],
                                  isViewAddOnsSwitchEnabled: Bool = false,
                                  isOrderCreationSwitchEnabled: Bool = false,
                                  knownCardReaders: [String] = [],
                                  lastEligibilityErrorInfo: EligibilityErrorInfo? = nil,
                                  lastJetpackBenefitsBannerDismissedTime: Date? = nil) -> GeneralAppSettings {
        GeneralAppSettings(installationDate: installationDate,
                           feedbacks: feedbacks,
                           isViewAddOnsSwitchEnabled: isViewAddOnsSwitchEnabled,
                           isOrderCreationSwitchEnabled: isOrderCreationSwitchEnabled,
                           knownCardReaders: knownCardReaders,
                           lastEligibilityErrorInfo: lastEligibilityErrorInfo,
                           lastJetpackBenefitsBannerDismissedTime: lastJetpackBenefitsBannerDismissedTime)
    }
}
