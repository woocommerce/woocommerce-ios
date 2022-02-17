import XCTest
@testable import Storage

final class GeneralAppSettingsTests: XCTestCase {
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
                                                  isStripeInPersonPaymentsSwitchEnabled: true,
                                                  isCanadaInPersonPaymentsSwitchEnabled: true,
                                                  isProductSKUInputScannerSwitchEnabled: true,
                                                  isCouponManagementSwitchEnabled: true,
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
        assertEqual(newSettings.isStripeInPersonPaymentsSwitchEnabled, true)
        assertEqual(newSettings.isCanadaInPersonPaymentsSwitchEnabled, true)
        assertEqual(newSettings.isProductSKUInputScannerSwitchEnabled, true)
        assertEqual(newSettings.isCouponManagementSwitchEnabled, true)
        assertEqual(newSettings.lastJetpackBenefitsBannerDismissedTime, jetpackBannerDismissedDate)
    }
}

private extension GeneralAppSettingsTests {
    func createGeneralAppSettings(installationDate: Date? = nil,
                                  feedbacks: [FeedbackType: FeedbackSettings] = [:],
                                  isViewAddOnsSwitchEnabled: Bool = false,
                                  isOrderCreationSwitchEnabled: Bool = false,
                                  isStripeInPersonPaymentsSwitchEnabled: Bool = false,
                                  isCanadaInPersonPaymentsSwitchEnabled: Bool = false,
                                  isProductSKUInputScannerSwitchEnabled: Bool = false,
                                  isCouponManagementSwitchEnabled: Bool = false,
                                  knownCardReaders: [String] = [],
                                  lastEligibilityErrorInfo: EligibilityErrorInfo? = nil,
                                  lastJetpackBenefitsBannerDismissedTime: Date? = nil) -> GeneralAppSettings {
        GeneralAppSettings(installationDate: installationDate,
                           feedbacks: feedbacks,
                           isViewAddOnsSwitchEnabled: isViewAddOnsSwitchEnabled,
                           isOrderCreationSwitchEnabled: isOrderCreationSwitchEnabled,
                           isStripeInPersonPaymentsSwitchEnabled: isStripeInPersonPaymentsSwitchEnabled,
                           isCanadaInPersonPaymentsSwitchEnabled: isCanadaInPersonPaymentsSwitchEnabled,
                           isProductSKUInputScannerSwitchEnabled: isProductSKUInputScannerSwitchEnabled,
                           isCouponManagementSwitchEnabled: isCouponManagementSwitchEnabled,
                           knownCardReaders: knownCardReaders,
                           lastEligibilityErrorInfo: lastEligibilityErrorInfo,
                           lastJetpackBenefitsBannerDismissedTime: lastJetpackBenefitsBannerDismissedTime)
    }
}
