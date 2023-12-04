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
        isInAppPurchasesSwitchEnabled: CopiableProp<Bool> = .copy,
        knownCardReaders: CopiableProp<[String]> = .copy,
        lastEligibilityErrorInfo: NullableCopiableProp<EligibilityErrorInfo> = .copy,
        lastJetpackBenefitsBannerDismissedTime: NullableCopiableProp<Date> = .copy,
        featureAnnouncementCampaignSettings: CopiableProp<[FeatureAnnouncementCampaign: FeatureAnnouncementCampaignSettings]> = .copy,
        sitesWithAtLeastOneIPPTransactionFinished: CopiableProp<Set<Int64>> = .copy,
        isEUShippingNoticeDismissed: CopiableProp<Bool> = .copy,
        localAnnouncementDismissed: CopiableProp<[LocalAnnouncement: Bool]> = .copy
    ) -> Storage.GeneralAppSettings {
        let installationDate = installationDate ?? self.installationDate
        let feedbacks = feedbacks ?? self.feedbacks
        let isViewAddOnsSwitchEnabled = isViewAddOnsSwitchEnabled ?? self.isViewAddOnsSwitchEnabled
        let isInAppPurchasesSwitchEnabled = isInAppPurchasesSwitchEnabled ?? self.isInAppPurchasesSwitchEnabled
        let knownCardReaders = knownCardReaders ?? self.knownCardReaders
        let lastEligibilityErrorInfo = lastEligibilityErrorInfo ?? self.lastEligibilityErrorInfo
        let lastJetpackBenefitsBannerDismissedTime = lastJetpackBenefitsBannerDismissedTime ?? self.lastJetpackBenefitsBannerDismissedTime
        let featureAnnouncementCampaignSettings = featureAnnouncementCampaignSettings ?? self.featureAnnouncementCampaignSettings
        let sitesWithAtLeastOneIPPTransactionFinished = sitesWithAtLeastOneIPPTransactionFinished ?? self.sitesWithAtLeastOneIPPTransactionFinished
        let isEUShippingNoticeDismissed = isEUShippingNoticeDismissed ?? self.isEUShippingNoticeDismissed
        let localAnnouncementDismissed = localAnnouncementDismissed ?? self.localAnnouncementDismissed

        return Storage.GeneralAppSettings(
            installationDate: installationDate,
            feedbacks: feedbacks,
            isViewAddOnsSwitchEnabled: isViewAddOnsSwitchEnabled,
            isInAppPurchasesSwitchEnabled: isInAppPurchasesSwitchEnabled,
            knownCardReaders: knownCardReaders,
            lastEligibilityErrorInfo: lastEligibilityErrorInfo,
            lastJetpackBenefitsBannerDismissedTime: lastJetpackBenefitsBannerDismissedTime,
            featureAnnouncementCampaignSettings: featureAnnouncementCampaignSettings,
            sitesWithAtLeastOneIPPTransactionFinished: sitesWithAtLeastOneIPPTransactionFinished,
            isEUShippingNoticeDismissed: isEUShippingNoticeDismissed,
            localAnnouncementDismissed: localAnnouncementDismissed
        )
    }
}

extension Storage.GeneralStoreSettings {
    public func copy(
        storeID: NullableCopiableProp<String> = .copy,
        isTelemetryAvailable: CopiableProp<Bool> = .copy,
        telemetryLastReportedTime: NullableCopiableProp<Date> = .copy,
        areSimplePaymentTaxesEnabled: CopiableProp<Bool> = .copy,
        preferredInPersonPaymentGateway: NullableCopiableProp<String> = .copy,
        skippedCashOnDeliveryOnboardingStep: CopiableProp<Bool> = .copy,
        lastSelectedStatsTimeRange: CopiableProp<String> = .copy,
        firstInPersonPaymentsTransactionsByReaderType: CopiableProp<[CardReaderType: Date]> = .copy,
        selectedTaxRateID: NullableCopiableProp<Int64> = .copy
    ) -> Storage.GeneralStoreSettings {
        let storeID = storeID ?? self.storeID
        let isTelemetryAvailable = isTelemetryAvailable ?? self.isTelemetryAvailable
        let telemetryLastReportedTime = telemetryLastReportedTime ?? self.telemetryLastReportedTime
        let areSimplePaymentTaxesEnabled = areSimplePaymentTaxesEnabled ?? self.areSimplePaymentTaxesEnabled
        let preferredInPersonPaymentGateway = preferredInPersonPaymentGateway ?? self.preferredInPersonPaymentGateway
        let skippedCashOnDeliveryOnboardingStep = skippedCashOnDeliveryOnboardingStep ?? self.skippedCashOnDeliveryOnboardingStep
        let lastSelectedStatsTimeRange = lastSelectedStatsTimeRange ?? self.lastSelectedStatsTimeRange
        let firstInPersonPaymentsTransactionsByReaderType = firstInPersonPaymentsTransactionsByReaderType ?? self.firstInPersonPaymentsTransactionsByReaderType
        let selectedTaxRateID = selectedTaxRateID ?? self.selectedTaxRateID

        return Storage.GeneralStoreSettings(
            storeID: storeID,
            isTelemetryAvailable: isTelemetryAvailable,
            telemetryLastReportedTime: telemetryLastReportedTime,
            areSimplePaymentTaxesEnabled: areSimplePaymentTaxesEnabled,
            preferredInPersonPaymentGateway: preferredInPersonPaymentGateway,
            skippedCashOnDeliveryOnboardingStep: skippedCashOnDeliveryOnboardingStep,
            lastSelectedStatsTimeRange: lastSelectedStatsTimeRange,
            firstInPersonPaymentsTransactionsByReaderType: firstInPersonPaymentsTransactionsByReaderType,
            selectedTaxRateID: selectedTaxRateID
        )
    }
}
