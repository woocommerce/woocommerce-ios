import UIKit

/// Spins the dashboard a full 360° the first time it appears after the app launches.
@MainActor
enum DashboardLaunchSpinAnimator {
    /// Process-wide so that recreating the dashboard (e.g. switching stores) does not spin it again.
    private static var hasSpun = false

    static func spinIfNeeded(_ view: UIView) {
        guard !hasSpun else {
            return
        }
        hasSpun = true
        guard !UIAccessibility.isReduceMotionEnabled else {
            return
        }

        // A Core Animation rotation only changes the presentation layer, so layout and the
        // navigation bar's large title tracking are unaffected, unlike a SwiftUI `rotationEffect`.
        let animation = CABasicAnimation(keyPath: "transform.rotation.z")
        animation.fromValue = 0
        animation.toValue = 2 * Double.pi
        animation.duration = Constants.duration
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        view.layer.add(animation, forKey: Constants.animationKey)
    }
}

private extension DashboardLaunchSpinAnimator {
    enum Constants {
        static let duration: CFTimeInterval = 0.8
        static let animationKey = "dashboardLaunchSpin"
    }
}
