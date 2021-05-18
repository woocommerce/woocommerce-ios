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

        guard let scene = currentScene else {
            return
        }
        // Show the app store ratings alert
        // Note: Optimistically assuming our prompting succeeds since we try to stay
        // in line and not prompt more than two times a year
        AppRatingManager.shared.ratedCurrentVersion()
        SKStoreReviewController.requestReview(in: scene)
    }
}

private extension UIViewController {
    /// Attempts to return the scene in with the current controller lives
    /// If its view is attached to a window, it will use the scene from that window
    /// Otherwise, it looks at it's ancestors for a valid window to find the scene
    var currentScene: UIWindowScene? {
        if let window = view.window {
            return window.windowScene
        }

        if let parent = parent {
            return parent.currentScene
        }

        return nil
    }
}
