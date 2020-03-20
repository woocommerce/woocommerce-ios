import Foundation


// MARK - UIViewController Helpers
extension UIViewController {

    /// Convenience method to instantiate a view controller from a storyboard.
    ///
    static func instantiate(from storyboard: Storyboard) -> Self? {
        return storyboard.instantiateViewController(ofClass: self)
    }
}
