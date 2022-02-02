// Generated using Sourcery 1.0.3 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT
import Codegen
import Foundation


extension GeneralAppSettings {
    public func copy(
        installationDate: NullableCopiableProp<Date> = .copy,
        feedbacks: CopiableProp<[FeedbackType: FeedbackSettings]> = .copy,
        isViewAddOnsSwitchEnabled: CopiableProp<Bool> = .copy,
        isOrderCreationSwitchEnabled: CopiableProp<Bool> = .copy,
        isStripeInPersonPaymentsSwitchEnabled: CopiableProp<Bool> = .copy,
        isCanadaInPersonPaymentsSwitchEnabled: CopiableProp<Bool> = .copy,
        isProductSKUInputScannerSwitchEnabled: CopiableProp<Bool> = .copy,
        knownCardReaders: CopiableProp<[String]> = .copy,
        lastEligibilityErrorInfo: NullableCopiableProp<EligibilityErrorInfo> = .copy,
        lastJetpackBenefitsBannerDismissedTime: NullableCopiableProp<Date> = .copy
    ) -> GeneralAppSettings {
        let installationDate = installationDate ?? self.installationDate
        let feedbacks = feedbacks ?? self.feedbacks
        let isViewAddOnsSwitchEnabled = isViewAddOnsSwitchEnabled ?? self.isViewAddOnsSwitchEnabled
        let isOrderCreationSwitchEnabled = isOrderCreationSwitchEnabled ?? self.isOrderCreationSwitchEnabled
        let isStripeInPersonPaymentsSwitchEnabled = isStripeInPersonPaymentsSwitchEnabled ?? self.isStripeInPersonPaymentsSwitchEnabled
        let isCanadaInPersonPaymentsSwitchEnabled = isCanadaInPersonPaymentsSwitchEnabled ?? self.isCanadaInPersonPaymentsSwitchEnabled
        let isProductSKUInputScannerSwitchEnabled = isProductSKUInputScannerSwitchEnabled ?? self.isProductSKUInputScannerSwitchEnabled
        let knownCardReaders = knownCardReaders ?? self.knownCardReaders
        let lastEligibilityErrorInfo = lastEligibilityErrorInfo ?? self.lastEligibilityErrorInfo
        let lastJetpackBenefitsBannerDismissedTime = lastJetpackBenefitsBannerDismissedTime ?? self.lastJetpackBenefitsBannerDismissedTime

        return GeneralAppSettings(
            installationDate: installationDate,
            feedbacks: feedbacks,
            isViewAddOnsSwitchEnabled: isViewAddOnsSwitchEnabled,
            isOrderCreationSwitchEnabled: isOrderCreationSwitchEnabled,
            isStripeInPersonPaymentsSwitchEnabled: isStripeInPersonPaymentsSwitchEnabled,
            isCanadaInPersonPaymentsSwitchEnabled: isCanadaInPersonPaymentsSwitchEnabled,
            isProductSKUInputScannerSwitchEnabled: isProductSKUInputScannerSwitchEnabled,
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
        areSimplePaymentTaxesEnabled: CopiableProp<Bool> = .copy
    ) -> GeneralStoreSettings {
        let isTelemetryAvailable = isTelemetryAvailable ?? self.isTelemetryAvailable
        let telemetryLastReportedTime = telemetryLastReportedTime ?? self.telemetryLastReportedTime
        let areSimplePaymentTaxesEnabled = areSimplePaymentTaxesEnabled ?? self.areSimplePaymentTaxesEnabled

        return GeneralStoreSettings(
            isTelemetryAvailable: isTelemetryAvailable,
            telemetryLastReportedTime: telemetryLastReportedTime,
            areSimplePaymentTaxesEnabled: areSimplePaymentTaxesEnabled
        )
    }
}
