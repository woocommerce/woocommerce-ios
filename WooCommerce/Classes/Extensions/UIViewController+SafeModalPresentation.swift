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
    /// Presents the given view controller only when no other modal is attached to this presenter.
    /// The presentation is dropped otherwise.
    ///
    /// A `UIAlertController` that is already being dismissed does not block the presentation, so
    /// that presenting from an alert action handler keeps working regardless of whether UIKit
    /// invokes the handler during or after the alert's dismissal.
    ///
    func presentIfIdle(_ viewControllerToPresent: UIViewController,
                       animated: Bool = true,
                       completion: (() -> Void)? = nil) {
        if let presented = presentedViewController {
            guard presented is UIAlertController, presented.isBeingDismissed else {
                DDLogWarn("⚠️ Dropped modal presentation of \(type(of: viewControllerToPresent)): " +
                          "already presenting \(type(of: presented))")
                return
            }
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
