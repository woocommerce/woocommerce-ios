import Foundation
import UIKit


/// UIView animation helpers
///
extension UIView {

    /// Unhides the current view by applying a fade-in animation.
    ///
    /// - Parameters:
    ///   - duration: The total duration of the animation, measured in seconds. (defaults to 0.5 seconds)
    ///   - delay: The amount of time (measured in seconds) to wait before beginning the animation.
    ///   - completion: The block executed when the animation sequence ends
    ///
    func fadeIn(duration: TimeInterval = 0.5, delay: TimeInterval = 0.0, completion: ((Bool) -> Void)? = nil) {
        self.alpha = 0.0

        UIView.animate(withDuration: duration, delay: delay, options: .curveEaseIn, animations: {
            self.isHidden = false
            self.alpha = 1.0
        }, completion: completion)
    }


    /// Hides the current view by applying a fade-out animation.
    ///
    /// - Parameters:
    ///   - duration: The total duration of the animations, measured in seconds. (defaults to 0.5 seconds)
    ///   - delay: The amount of time (measured in seconds) to wait before beginning the animation.
    ///   - completion: The block executed when the animation sequence ends
    ///
    func fadeOut(duration: TimeInterval = 0.5, delay: TimeInterval = 0.0, completion: ((Bool) -> Void)? = nil) {
        self.alpha = 1.0

        UIView.animate(withDuration: duration, delay: delay, options: .curveEaseIn, animations: {
            self.alpha = 0.0
        }) { finished in
            self.isHidden = true
            completion?(finished)
        }
    }
}
