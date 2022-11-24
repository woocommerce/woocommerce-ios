// Generated using Sourcery 1.0.3 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT
import Codegen
import Foundation


extension Storage.FeatureAnnouncementCampaignSettings {
    public func copy(
        dismissedDate: NullableCopiableProp<Date> = .copy,
        remindAfter: NullableCopiableProp<Date> = .copy
    ) -> Storage.FeatureAnnouncementCampaignSettings {
        let dismissedDate = dismissedDate ?? self.dismissedDate
        let remindAfter = remindAfter ?? self.remindAfter

        return Storage.FeatureAnnouncementCampaignSettings(
            dismissedDate: dismissedDate,
            remindAfter: remindAfter
        )
    }
}

extension Storage.GeneralAppSettings {
    public func copy(
        installationDate: NullableCopiableProp<Date> = .copy,
        feedbacks: CopiableProp<[FeedbackType: FeedbackSettings]> = .copy,
        isViewAddOnsSwitchEnabled: CopiableProp<Bool> = .copy,
        isProductSKUInputScannerSwitchEnabled: CopiableProp<Bool> = .copy,
        isCouponManagementSwitchEnabled: CopiableProp<Bool> = .copy,
        isInAppPurchasesSwitchEnabled: CopiableProp<Bool> = .copy,
        knownCardReaders: CopiableProp<[String]> = .copy,
        lastEligibilityErrorInfo: NullableCopiableProp<EligibilityErrorInfo> = .copy,
        lastJetpackBenefitsBannerDismissedTime: NullableCopiableProp<Date> = .copy,
        featureAnnouncementCampaignSettings: CopiableProp<[FeatureAnnouncementCampaign: FeatureAnnouncementCampaignSettings]> = .copy
    ) -> Storage.GeneralAppSettings {
        let installationDate = installationDate ?? self.installationDate
        let feedbacks = feedbacks ?? self.feedbacks
        let isViewAddOnsSwitchEnabled = isViewAddOnsSwitchEnabled ?? self.isViewAddOnsSwitchEnabled
        let isProductSKUInputScannerSwitchEnabled = isProductSKUInputScannerSwitchEnabled ?? self.isProductSKUInputScannerSwitchEnabled
        let isCouponManagementSwitchEnabled = isCouponManagementSwitchEnabled ?? self.isCouponManagementSwitchEnabled
        let isInAppPurchasesSwitchEnabled = isInAppPurchasesSwitchEnabled ?? self.isInAppPurchasesSwitchEnabled
        let knownCardReaders = knownCardReaders ?? self.knownCardReaders
        let lastEligibilityErrorInfo = lastEligibilityErrorInfo ?? self.lastEligibilityErrorInfo
        let lastJetpackBenefitsBannerDismissedTime = lastJetpackBenefitsBannerDismissedTime ?? self.lastJetpackBenefitsBannerDismissedTime
        let featureAnnouncementCampaignSettings = featureAnnouncementCampaignSettings ?? self.featureAnnouncementCampaignSettings

        return Storage.GeneralAppSettings(
            installationDate: installationDate,
            feedbacks: feedbacks,
            isViewAddOnsSwitchEnabled: isViewAddOnsSwitchEnabled,
            isProductSKUInputScannerSwitchEnabled: isProductSKUInputScannerSwitchEnabled,
            isCouponManagementSwitchEnabled: isCouponManagementSwitchEnabled,
            isInAppPurchasesSwitchEnabled: isInAppPurchasesSwitchEnabled,
            knownCardReaders: knownCardReaders,
            lastEligibilityErrorInfo: lastEligibilityErrorInfo,
            lastJetpackBenefitsBannerDismissedTime: lastJetpackBenefitsBannerDismissedTime,
            featureAnnouncementCampaignSettings: featureAnnouncementCampaignSettings
        )
    }
}

extension Storage.GeneralStoreSettings {
    public func copy(
        isTelemetryAvailable: CopiableProp<Bool> = .copy,
        telemetryLastReportedTime: NullableCopiableProp<Date> = .copy,
        areSimplePaymentTaxesEnabled: CopiableProp<Bool> = .copy,
        preferredInPersonPaymentGateway: NullableCopiableProp<String> = .copy,
        skippedCashOnDeliveryOnboardingStep: CopiableProp<Bool> = .copy,
        lastSelectedStatsTimeRange: CopiableProp<String> = .copy
    ) -> Storage.GeneralStoreSettings {
        let isTelemetryAvailable = isTelemetryAvailable ?? self.isTelemetryAvailable
        let telemetryLastReportedTime = telemetryLastReportedTime ?? self.telemetryLastReportedTime
        let areSimplePaymentTaxesEnabled = areSimplePaymentTaxesEnabled ?? self.areSimplePaymentTaxesEnabled
        let preferredInPersonPaymentGateway = preferredInPersonPaymentGateway ?? self.preferredInPersonPaymentGateway
        let skippedCashOnDeliveryOnboardingStep = skippedCashOnDeliveryOnboardingStep ?? self.skippedCashOnDeliveryOnboardingStep
        let lastSelectedStatsTimeRange = lastSelectedStatsTimeRange ?? self.lastSelectedStatsTimeRange

        return Storage.GeneralStoreSettings(
            isTelemetryAvailable: isTelemetryAvailable,
            telemetryLastReportedTime: telemetryLastReportedTime,
            areSimplePaymentTaxesEnabled: areSimplePaymentTaxesEnabled,
            preferredInPersonPaymentGateway: preferredInPersonPaymentGateway,
            skippedCashOnDeliveryOnboardingStep: skippedCashOnDeliveryOnboardingStep,
            lastSelectedStatsTimeRange: lastSelectedStatsTimeRange
        )
    }
}
