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

    func test_isPOSSurveyPotentialMerchantNotificationScheduled_defaults_to_false() {
        // Given
        let settings = createGeneralAppSettings()

        // Then
        XCTAssertFalse(settings.isPOSSurveyPotentialMerchantNotificationScheduled)
    }

    func test_isPOSSurveyCurrentMerchantNotificationScheduled_defaults_to_false() {
        // Given
        let settings = createGeneralAppSettings()

        // Then
        XCTAssertFalse(settings.isPOSSurveyCurrentMerchantNotificationScheduled)
    }

    func test_hasPOSBeenOpenedAtLeastOnce_defaults_to_false() {
        // Given
        let settings = createGeneralAppSettings()

        // Then
        XCTAssertFalse(settings.hasPOSBeenOpenedAtLeastOnce)
    }

    func test_updating_properties_to_generalAppSettings_does_not_breaks_decoding() throws {
        // Given
        let installationDate = Date(timeIntervalSince1970: 1630314000) // Mon Aug 30 2021 09:00:00 UTC+0000
        let jetpackBannerDismissedDate = Date(timeIntervalSince1970: 1631523600) // Mon Sep 13 2021 09:00:00 UTC+0000
        let feedbackSettings = [FeedbackType.general: FeedbackSettings(name: .general, status: .pending)]
        let readers = ["aaaaa", "bbbbbb"]
        let eligibilityInfo = EligibilityErrorInfo(name: "user", roles: ["admin"])
        let featureAnnouncementCampaignSettings = [
            FeatureAnnouncementCampaign.linkedProductsPromo:
                FeatureAnnouncementCampaignSettings(dismissedDate: Date(), remindAfter: nil)]
        let sitesWithAtLeastOneIPPTransactionFinished: Set<Int64> = [1234, 123, 12, 1]
        let isCustomFieldsTopBannerDismissed = true
        let isPOSSurveyPotentialMerchantNotificationScheduled = true
        let isPOSSurveyCurrentMerchantNotificationScheduled = true
        let hasPOSBeenOpenedAtLeastOnce = true
        let previousSettings = GeneralAppSettings(installationDate: installationDate,
                                                  feedbacks: feedbackSettings,
                                                  isViewAddOnsSwitchEnabled: true,
                                                  isApplicationPasswordsSwitchEnabled: false,
                                                  isPOSLocalCatalogSwitchEnabled: true,
                                                  knownCardReaders: readers,
                                                  lastEligibilityErrorInfo: eligibilityInfo,
                                                  lastJetpackBenefitsBannerDismissedTime: jetpackBannerDismissedDate,
                                                  featureAnnouncementCampaignSettings: featureAnnouncementCampaignSettings,
                                                  sitesWithAtLeastOneIPPTransactionFinished: sitesWithAtLeastOneIPPTransactionFinished,
                                                  isEUShippingNoticeDismissed: false,
                                                  isCustomFieldsTopBannerDismissed: isCustomFieldsTopBannerDismissed,
                                                  isPOSSurveyPotentialMerchantNotificationScheduled: isPOSSurveyPotentialMerchantNotificationScheduled,
                                                  isPOSSurveyCurrentMerchantNotificationScheduled: isPOSSurveyCurrentMerchantNotificationScheduled,
                                                  hasPOSBeenOpenedAtLeastOnce: hasPOSBeenOpenedAtLeastOnce)

        let previousEncodedSettings = try JSONEncoder().encode(previousSettings)
        var previousSettingsJson = try JSONSerialization.jsonObject(with: previousEncodedSettings, options: .allowFragments) as? [String: Any]

        // When
        previousSettingsJson?.removeValue(forKey: "isViewAddOnsSwitchEnabled")
        previousSettingsJson?.removeValue(forKey: "isPOSSurveyPotentialMerchantNotificationScheduled")
        previousSettingsJson?.removeValue(forKey: "isPOSSurveyCurrentMerchantNotificationScheduled")
        previousSettingsJson?.removeValue(forKey: "hasPOSBeenOpenedAtLeastOnce")
        let newEncodedSettings = try JSONSerialization.data(withJSONObject: previousSettingsJson as Any, options: .fragmentsAllowed)
        let newSettings = try JSONDecoder().decode(GeneralAppSettings.self, from: newEncodedSettings)

        // Then
        assertEqual(newSettings.installationDate, installationDate)
        assertEqual(newSettings.feedbacks, feedbackSettings)
        assertEqual(newSettings.knownCardReaders, readers)
        assertEqual(newSettings.lastEligibilityErrorInfo, eligibilityInfo)
        assertEqual(newSettings.isViewAddOnsSwitchEnabled, false)
        assertEqual(newSettings.lastJetpackBenefitsBannerDismissedTime, jetpackBannerDismissedDate)
        assertEqual(newSettings.featureAnnouncementCampaignSettings, featureAnnouncementCampaignSettings)
        assertEqual(newSettings.sitesWithAtLeastOneIPPTransactionFinished, sitesWithAtLeastOneIPPTransactionFinished)
        assertEqual(newSettings.isCustomFieldsTopBannerDismissed, isCustomFieldsTopBannerDismissed)
        assertEqual(newSettings.isPOSSurveyPotentialMerchantNotificationScheduled, false)
        assertEqual(newSettings.isPOSSurveyCurrentMerchantNotificationScheduled, false)
        assertEqual(newSettings.hasPOSBeenOpenedAtLeastOnce, false)
    }
}

private typealias Campaign = FeatureAnnouncementCampaign
private typealias CampaignSettings = FeatureAnnouncementCampaignSettings

private extension GeneralAppSettingsTests {
    func createGeneralAppSettings(installationDate: Date? = nil,
                                  feedbacks: [FeedbackType: FeedbackSettings] = [:],
                                  isViewAddOnsSwitchEnabled: Bool = false,
                                  isSwiftUIPaymentsMenuSwitchEnabled: Bool = false,
                                  knownCardReaders: [String] = [],
                                  lastEligibilityErrorInfo: EligibilityErrorInfo? = nil,
                                  lastJetpackBenefitsBannerDismissedTime: Date? = nil,
                                  featureAnnouncementCampaignSettings: [Campaign: CampaignSettings] = [:],
                                  sitesWithAtLeastOneIPPTransactionFinished: Set<Int64> = [],
                                  isEUShippingNoticeDismissed: Bool = false,
                                  isCustomFieldsTopBannerDismissed: Bool = false,
                                  isPOSSurveyPotentialMerchantNotificationScheduled: Bool = false,
                                  isPOSSurveyCurrentMerchantNotificationScheduled: Bool = false,
                                  hasPOSBeenOpenedAtLeastOnce: Bool = false
    ) -> GeneralAppSettings {
        GeneralAppSettings(installationDate: installationDate,
                           feedbacks: feedbacks,
                           isViewAddOnsSwitchEnabled: isViewAddOnsSwitchEnabled,
                           isApplicationPasswordsSwitchEnabled: false,
                           isPOSLocalCatalogSwitchEnabled: true,
                           knownCardReaders: knownCardReaders,
                           lastEligibilityErrorInfo: lastEligibilityErrorInfo,
                           lastJetpackBenefitsBannerDismissedTime: lastJetpackBenefitsBannerDismissedTime,
                           featureAnnouncementCampaignSettings: featureAnnouncementCampaignSettings,
                           sitesWithAtLeastOneIPPTransactionFinished: sitesWithAtLeastOneIPPTransactionFinished,
                           isEUShippingNoticeDismissed: isEUShippingNoticeDismissed,
                           isCustomFieldsTopBannerDismissed: isCustomFieldsTopBannerDismissed,
                           isPOSSurveyPotentialMerchantNotificationScheduled: isPOSSurveyPotentialMerchantNotificationScheduled,
                           isPOSSurveyCurrentMerchantNotificationScheduled: isPOSSurveyCurrentMerchantNotificationScheduled,
                           hasPOSBeenOpenedAtLeastOnce: hasPOSBeenOpenedAtLeastOnce)
    }
}
