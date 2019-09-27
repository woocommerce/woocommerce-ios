import UIKit
import StoreKit

extension UIViewController {
    // MARK: - App Store Review Prompt
    //
    func displayRatingPrompt() {
        defer {
            if let wooEvent = WooAnalyticsStat.valueOf(stat: .appReviewsRatedApp) {
                ServiceLocator.analytics.track(wooEvent)
            }
        }

        // Show the app store ratings alert
        // Note: Optimistically assuming our prompting succeeds since we try to stay
        // in line and not prompt more than two times a year
        AppRatingManager.shared.ratedCurrentVersion()
        SKStoreReviewController.requestReview()
    }
}
