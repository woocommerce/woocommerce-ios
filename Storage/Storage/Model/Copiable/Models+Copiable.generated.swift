// Generated using Sourcery 1.0.3 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT
import Codegen
import Foundation


extension GeneralAppSettings {
    public func copy(
        installationDate: NullableCopiableProp<Date> = .copy,
        feedbacks: CopiableProp<[FeedbackType: FeedbackSettings]> = .copy,
        isViewAddOnsSwitchEnabled: CopiableProp<Bool> = .copy,
        isProductSKUInputScannerSwitchEnabled: CopiableProp<Bool> = .copy,
        isCouponManagementSwitchEnabled: CopiableProp<Bool> = .copy,
        knownCardReaders: CopiableProp<[String]> = .copy,
        lastEligibilityErrorInfo: NullableCopiableProp<EligibilityErrorInfo> = .copy,
        lastJetpackBenefitsBannerDismissedTime: NullableCopiableProp<Date> = .copy
    ) -> GeneralAppSettings {
        let installationDate = installationDate ?? self.installationDate
        let feedbacks = feedbacks ?? self.feedbacks
        let isViewAddOnsSwitchEnabled = isViewAddOnsSwitchEnabled ?? self.isViewAddOnsSwitchEnabled
        let isProductSKUInputScannerSwitchEnabled = isProductSKUInputScannerSwitchEnabled ?? self.isProductSKUInputScannerSwitchEnabled
        let isCouponManagementSwitchEnabled = isCouponManagementSwitchEnabled ?? self.isCouponManagementSwitchEnabled
        let knownCardReaders = knownCardReaders ?? self.knownCardReaders
        let lastEligibilityErrorInfo = lastEligibilityErrorInfo ?? self.lastEligibilityErrorInfo
        let lastJetpackBenefitsBannerDismissedTime = lastJetpackBenefitsBannerDismissedTime ?? self.lastJetpackBenefitsBannerDismissedTime

        return GeneralAppSettings(
            installationDate: installationDate,
            feedbacks: feedbacks,
            isViewAddOnsSwitchEnabled: isViewAddOnsSwitchEnabled,
            isProductSKUInputScannerSwitchEnabled: isProductSKUInputScannerSwitchEnabled,
            isCouponManagementSwitchEnabled: isCouponManagementSwitchEnabled,
            knownCardReaders: knownCardReaders,
            lastEligibilityErrorInfo: lastEligibilityErrorInfo,
            lastJetpackBenefitsBannerDismissedTime: lastJetpackBenefitsBannerDismissedTime
        )
    }
}

extension GeneralStoreSettings {
    public func copy(
        isTelemetryAvailable: CopiableProp<Bool> = .copy,
        telemetryLastReportedTime: NullableCopiableProp<Date> = .copy,
        areSimplePaymentTaxesEnabled: CopiableProp<Bool> = .copy,
        preferredInPersonPaymentGateway: NullableCopiableProp<String> = .copy
    ) -> GeneralStoreSettings {
        let isTelemetryAvailable = isTelemetryAvailable ?? self.isTelemetryAvailable
        let telemetryLastReportedTime = telemetryLastReportedTime ?? self.telemetryLastReportedTime
        let areSimplePaymentTaxesEnabled = areSimplePaymentTaxesEnabled ?? self.areSimplePaymentTaxesEnabled
        let preferredInPersonPaymentGateway = preferredInPersonPaymentGateway ?? self.preferredInPersonPaymentGateway

        return GeneralStoreSettings(
            isTelemetryAvailable: isTelemetryAvailable,
            telemetryLastReportedTime: telemetryLastReportedTime,
            areSimplePaymentTaxesEnabled: areSimplePaymentTaxesEnabled,
            preferredInPersonPaymentGateway: preferredInPersonPaymentGateway
        )
    }
}
