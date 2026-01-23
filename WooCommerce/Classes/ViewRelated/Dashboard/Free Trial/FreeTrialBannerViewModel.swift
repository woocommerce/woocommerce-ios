import Foundation
import Yosemite

/// ViewModel to format the text that goes into the Free Trial Banner.
///
struct FreeTrialBannerViewModel {

    /// Free Trial banner message.
    ///
    let message: String

    init(sitePlan: WPComSitePlan, timeZone: TimeZone = .current, calendar: Calendar = .current) {

        // Normalize dates in the same timezone.
        let today = Date().startOfDay(timezone: timeZone)
        guard let expiryDate = sitePlan.expiryDate?.startOfDay(timezone: timeZone) else {
            message = ""
            return
        }

        let daysLeft = calendar.dateComponents([.day], from: today, to: expiryDate).day ?? 0
        switch daysLeft {
        case 1:
            message = NSLocalizedString("1 day left in your trial.", comment: "This text appears in a free trial banner on the dashboard when exactly one day remains in the user's trial period. It's part of a notification system that updates daily to inform users about their trial status and likely encourages them to upgrade before expiration.")
        case (2...):
            let format = NSLocalizedString("%d days left in your trial.", comment: "This text appears as a banner message on the app's dashboard to inform users how many days remain in their free trial period. The %d placeholder is replaced with the actual number of days (2 or more) remaining before the trial expires.")
            message = String.localizedStringWithFormat(format, daysLeft)
        default:
            message = NSLocalizedString("Your trial has ended.", comment: "Message of the free trial banner when there are no days left")

        }
    }
}
