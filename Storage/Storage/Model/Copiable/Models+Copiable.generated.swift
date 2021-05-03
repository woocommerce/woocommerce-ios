// Generated using Sourcery 1.0.3 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT
import Networking


extension GeneralAppSettings {
    public func copy(
        installationDate: NullableCopiableProp<Date> = .copy,
        feedbacks: CopiableProp<[FeedbackType: FeedbackSettings]> = .copy,
        isViewAddOnsSwitchEnabled: CopiableProp<Bool> = .copy
    ) -> GeneralAppSettings {
        let installationDate = installationDate ?? self.installationDate
        let feedbacks = feedbacks ?? self.feedbacks
        let isViewAddOnsSwitchEnabled = isViewAddOnsSwitchEnabled ?? self.isViewAddOnsSwitchEnabled

        return GeneralAppSettings(
            installationDate: installationDate,
            feedbacks: feedbacks,
            isViewAddOnsSwitchEnabled: isViewAddOnsSwitchEnabled
        )
    }
}
