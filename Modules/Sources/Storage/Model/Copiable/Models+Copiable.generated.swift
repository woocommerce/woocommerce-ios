// Generated using Sourcery 2.3.0 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT
import Codegen
import Foundation

// swiftlint:disable line_length

extension Storage.AnalyticsCard {
    public func copy(
        type: CopiableProp<AnalyticsCard.CardType> = .copy,
        enabled: CopiableProp<Bool> = .copy
    ) -> Storage.AnalyticsCard {
        let type = type ?? self.type
        let enabled = enabled ?? self.enabled

        return Storage.AnalyticsCard(
            type: type,
            enabled: enabled
        )
    }
}

extension Storage.DashboardCard {
    public func copy(
        type: CopiableProp<DashboardCard.CardType> = .copy,
        availability: CopiableProp<DashboardCard.AvailabilityState> = .copy,
        enabled: CopiableProp<Bool> = .copy
    ) -> Storage.DashboardCard {
        let type = type ?? self.type
        let availability = availability ?? self.availability
        let enabled = enabled ?? self.enabled

        return Storage.DashboardCard(
            type: type,
            availability: availability,
            enabled: enabled
        )
    }
}

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
        isApplicationPasswordsSwitchEnabled: CopiableProp<Bool> = .copy,
        isPOSLocalCatalogSwitchEnabled: CopiableProp<Bool> = .copy,
        knownCardReaders: CopiableProp<[String]> = .copy,
        lastEligibilityErrorInfo: NullableCopiableProp<EligibilityErrorInfo> = .copy,
        lastJetpackBenefitsBannerDismissedTime: NullableCopiableProp<Date> = .copy,
        featureAnnouncementCampaignSettings: CopiableProp<[FeatureAnnouncementCampaign: FeatureAnnouncementCampaignSettings]> = .copy,
        sitesWithAtLeastOneIPPTransactionFinished: CopiableProp<Set<Int64>> = .copy,
        isEUShippingNoticeDismissed: CopiableProp<Bool> = .copy,
        isCustomFieldsTopBannerDismissed: CopiableProp<Bool> = .copy,
        isPOSSurveyPotentialMerchantNotificationScheduled: CopiableProp<Bool> = .copy,
        isPOSSurveyCurrentMerchantNotificationScheduled: CopiableProp<Bool> = .copy,
        hasPOSBeenOpenedAtLeastOnce: CopiableProp<Bool> = .copy
    ) -> Storage.GeneralAppSettings {
        let installationDate = installationDate ?? self.installationDate
        let feedbacks = feedbacks ?? self.feedbacks
        let isViewAddOnsSwitchEnabled = isViewAddOnsSwitchEnabled ?? self.isViewAddOnsSwitchEnabled
        let isApplicationPasswordsSwitchEnabled = isApplicationPasswordsSwitchEnabled ?? self.isApplicationPasswordsSwitchEnabled
        let isPOSLocalCatalogSwitchEnabled = isPOSLocalCatalogSwitchEnabled ?? self.isPOSLocalCatalogSwitchEnabled
        let knownCardReaders = knownCardReaders ?? self.knownCardReaders
        let lastEligibilityErrorInfo = lastEligibilityErrorInfo ?? self.lastEligibilityErrorInfo
        let lastJetpackBenefitsBannerDismissedTime = lastJetpackBenefitsBannerDismissedTime ?? self.lastJetpackBenefitsBannerDismissedTime
        let featureAnnouncementCampaignSettings = featureAnnouncementCampaignSettings ?? self.featureAnnouncementCampaignSettings
        let sitesWithAtLeastOneIPPTransactionFinished = sitesWithAtLeastOneIPPTransactionFinished ?? self.sitesWithAtLeastOneIPPTransactionFinished
        let isEUShippingNoticeDismissed = isEUShippingNoticeDismissed ?? self.isEUShippingNoticeDismissed
        let isCustomFieldsTopBannerDismissed = isCustomFieldsTopBannerDismissed ?? self.isCustomFieldsTopBannerDismissed
        let isPOSSurveyPotentialMerchantNotificationScheduled = isPOSSurveyPotentialMerchantNotificationScheduled ?? self.isPOSSurveyPotentialMerchantNotificationScheduled
        let isPOSSurveyCurrentMerchantNotificationScheduled = isPOSSurveyCurrentMerchantNotificationScheduled ?? self.isPOSSurveyCurrentMerchantNotificationScheduled
        let hasPOSBeenOpenedAtLeastOnce = hasPOSBeenOpenedAtLeastOnce ?? self.hasPOSBeenOpenedAtLeastOnce

        return Storage.GeneralAppSettings(
            installationDate: installationDate,
            feedbacks: feedbacks,
            isViewAddOnsSwitchEnabled: isViewAddOnsSwitchEnabled,
            isApplicationPasswordsSwitchEnabled: isApplicationPasswordsSwitchEnabled,
            isPOSLocalCatalogSwitchEnabled: isPOSLocalCatalogSwitchEnabled,
            knownCardReaders: knownCardReaders,
            lastEligibilityErrorInfo: lastEligibilityErrorInfo,
            lastJetpackBenefitsBannerDismissedTime: lastJetpackBenefitsBannerDismissedTime,
            featureAnnouncementCampaignSettings: featureAnnouncementCampaignSettings,
            sitesWithAtLeastOneIPPTransactionFinished: sitesWithAtLeastOneIPPTransactionFinished,
            isEUShippingNoticeDismissed: isEUShippingNoticeDismissed,
            isCustomFieldsTopBannerDismissed: isCustomFieldsTopBannerDismissed,
            isPOSSurveyPotentialMerchantNotificationScheduled: isPOSSurveyPotentialMerchantNotificationScheduled,
            isPOSSurveyCurrentMerchantNotificationScheduled: isPOSSurveyCurrentMerchantNotificationScheduled,
            hasPOSBeenOpenedAtLeastOnce: hasPOSBeenOpenedAtLeastOnce
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
        customStatsTimeRange: CopiableProp<String> = .copy,
        firstInPersonPaymentsTransactionsByReaderType: CopiableProp<[CardReaderType: Date]> = .copy,
        selectedTaxRateID: NullableCopiableProp<Int64> = .copy,
        analyticsHubCards: NullableCopiableProp<[AnalyticsCard]> = .copy,
        dashboardCards: NullableCopiableProp<[DashboardCard]> = .copy,
        lastSelectedPerformanceTimeRange: CopiableProp<String> = .copy,
        lastSelectedDashboardRevenueStatsType: CopiableProp<String> = .copy,
        lastSelectedTopPerformersTimeRange: CopiableProp<String> = .copy,
        lastSelectedMostActiveCouponsTimeRange: CopiableProp<String> = .copy,
        lastSelectedStockType: NullableCopiableProp<String> = .copy,
        lastSelectedOrderStatus: NullableCopiableProp<String> = .copy,
        favoriteProductIDs: CopiableProp<[Int64]> = .copy,
        searchTermsByKey: CopiableProp<[String: [String]]> = .copy,
        isPOSTabVisible: NullableCopiableProp<Bool> = .copy,
        lastPOSOpenedDate: NullableCopiableProp<Date> = .copy,
        firstPOSCatalogSyncDate: NullableCopiableProp<Date> = .copy,
        syncPOSCatalogOverCellular: CopiableProp<Bool> = .copy,
        lastSunsetWarningDismissedDate: NullableCopiableProp<Date> = .copy
    ) -> Storage.GeneralStoreSettings {
        let storeID = storeID ?? self.storeID
        let isTelemetryAvailable = isTelemetryAvailable ?? self.isTelemetryAvailable
        let telemetryLastReportedTime = telemetryLastReportedTime ?? self.telemetryLastReportedTime
        let areSimplePaymentTaxesEnabled = areSimplePaymentTaxesEnabled ?? self.areSimplePaymentTaxesEnabled
        let preferredInPersonPaymentGateway = preferredInPersonPaymentGateway ?? self.preferredInPersonPaymentGateway
        let skippedCashOnDeliveryOnboardingStep = skippedCashOnDeliveryOnboardingStep ?? self.skippedCashOnDeliveryOnboardingStep
        let lastSelectedStatsTimeRange = lastSelectedStatsTimeRange ?? self.lastSelectedStatsTimeRange
        let customStatsTimeRange = customStatsTimeRange ?? self.customStatsTimeRange
        let firstInPersonPaymentsTransactionsByReaderType = firstInPersonPaymentsTransactionsByReaderType ?? self.firstInPersonPaymentsTransactionsByReaderType
        let selectedTaxRateID = selectedTaxRateID ?? self.selectedTaxRateID
        let analyticsHubCards = analyticsHubCards ?? self.analyticsHubCards
        let dashboardCards = dashboardCards ?? self.dashboardCards
        let lastSelectedPerformanceTimeRange = lastSelectedPerformanceTimeRange ?? self.lastSelectedPerformanceTimeRange
        let lastSelectedDashboardRevenueStatsType = lastSelectedDashboardRevenueStatsType ?? self.lastSelectedDashboardRevenueStatsType
        let lastSelectedTopPerformersTimeRange = lastSelectedTopPerformersTimeRange ?? self.lastSelectedTopPerformersTimeRange
        let lastSelectedMostActiveCouponsTimeRange = lastSelectedMostActiveCouponsTimeRange ?? self.lastSelectedMostActiveCouponsTimeRange
        let lastSelectedStockType = lastSelectedStockType ?? self.lastSelectedStockType
        let lastSelectedOrderStatus = lastSelectedOrderStatus ?? self.lastSelectedOrderStatus
        let favoriteProductIDs = favoriteProductIDs ?? self.favoriteProductIDs
        let searchTermsByKey = searchTermsByKey ?? self.searchTermsByKey
        let isPOSTabVisible = isPOSTabVisible ?? self.isPOSTabVisible
        let lastPOSOpenedDate = lastPOSOpenedDate ?? self.lastPOSOpenedDate
        let firstPOSCatalogSyncDate = firstPOSCatalogSyncDate ?? self.firstPOSCatalogSyncDate
        let syncPOSCatalogOverCellular = syncPOSCatalogOverCellular ?? self.syncPOSCatalogOverCellular
        let lastSunsetWarningDismissedDate = lastSunsetWarningDismissedDate ?? self.lastSunsetWarningDismissedDate

        return Storage.GeneralStoreSettings(
            storeID: storeID,
            isTelemetryAvailable: isTelemetryAvailable,
            telemetryLastReportedTime: telemetryLastReportedTime,
            areSimplePaymentTaxesEnabled: areSimplePaymentTaxesEnabled,
            preferredInPersonPaymentGateway: preferredInPersonPaymentGateway,
            skippedCashOnDeliveryOnboardingStep: skippedCashOnDeliveryOnboardingStep,
            lastSelectedStatsTimeRange: lastSelectedStatsTimeRange,
            customStatsTimeRange: customStatsTimeRange,
            firstInPersonPaymentsTransactionsByReaderType: firstInPersonPaymentsTransactionsByReaderType,
            selectedTaxRateID: selectedTaxRateID,
            analyticsHubCards: analyticsHubCards,
            dashboardCards: dashboardCards,
            lastSelectedPerformanceTimeRange: lastSelectedPerformanceTimeRange,
            lastSelectedDashboardRevenueStatsType: lastSelectedDashboardRevenueStatsType,
            lastSelectedTopPerformersTimeRange: lastSelectedTopPerformersTimeRange,
            lastSelectedMostActiveCouponsTimeRange: lastSelectedMostActiveCouponsTimeRange,
            lastSelectedStockType: lastSelectedStockType,
            lastSelectedOrderStatus: lastSelectedOrderStatus,
            favoriteProductIDs: favoriteProductIDs,
            searchTermsByKey: searchTermsByKey,
            isPOSTabVisible: isPOSTabVisible,
            lastPOSOpenedDate: lastPOSOpenedDate,
            firstPOSCatalogSyncDate: firstPOSCatalogSyncDate,
            syncPOSCatalogOverCellular: syncPOSCatalogOverCellular,
            lastSunsetWarningDismissedDate: lastSunsetWarningDismissedDate
        )
    }
}

// swiftlint:enable line_length
