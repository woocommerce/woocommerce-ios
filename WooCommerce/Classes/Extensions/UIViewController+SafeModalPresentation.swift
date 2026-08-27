import UIKit

/// Guards against stacked or raced modal presentations.
///
/// On iOS 26, presenting a second sheet while another modal transition is attached to the same
/// presenter corrupts UIKit's internal `_UISheetInteraction` state: the sheet stops responding to
/// dismissal and the next scroll-view pan crashes with an `NSRangeException`
/// (see https://linear.app/a8c/issue/WOOMOB-3923). Repeated taps that would stack a modal are
/// re-triggers of the same user intent, so dropping the duplicate presentation is the safe response.
///
extension UIViewController {
    /// Presents the given view controller only when no other modal is attached to this presenter —
    /// including one still mid-transition. The presentation is dropped otherwise.
    ///
    /// Presenting from a `UIAlertController` action handler is compatible with this guard: UIKit
    /// invokes action handlers after the alert's dismissal completes, when `presentedViewController`
    /// is already `nil`.
    ///
    func presentIfIdle(_ viewControllerToPresent: UIViewController,
                       animated: Bool = true,
                       completion: (() -> Void)? = nil) {
        guard presentedViewController == nil else {
            DDLogWarn("⚠️ Dropped modal presentation of \(type(of: viewControllerToPresent)): " +
                      "already presenting \(type(of: presentedViewController!))")
            return
        }
        present(viewControllerToPresent, animated: animated, completion: completion)
    }

    /// Dismisses the currently presented view controller unless a dismissal is already in flight.
    ///
    func dismissPresentedIfNeeded(animated: Bool = true, completion: (() -> Void)? = nil) {
        guard let presented = presentedViewController, !presented.isBeingDismissed else {
            return
        }
        presented.dismiss(animated: animated, completion: completion)
    }
}
