import Yosemite

/// ViewModel to format the text that goes into the Free Trial Banner.
///
struct FreeTrialBannerViewModel {

    /// Free Trial banner message.
    ///
    let message: String

    init(sitePlan: WPComSitePlan) {

        // Normalize dates in the same timezone.
        let today = Date().startOfDay(timezone: .current)
        guard let expiryDate = sitePlan.expiryDate?.startOfDay(timezone: .current) else {
            message = ""
            return
        }

        let daysLeft = Calendar.current.dateComponents([.day], from: today, to: expiryDate).day ?? 0
        switch daysLeft {
        case 1:
            message = NSLocalizedString("1 day left in your trial.", comment: "Message of the free trial banner when there is 1 day left")
        case (2...):
            let format = NSLocalizedString("%d days left in your trial.", comment: "Message of the free trial banner when there is more than 1 day left")
            message = String.localizedStringWithFormat(format, daysLeft)
        default:
            message = NSLocalizedString("Your trial has ended.", comment: "Message of the free trial banner when there are no days left")

        }
    }
}
