
import UIKit

/// A ViewController that provides additional adjustment for when the keyboard is shown.
///
/// This is used by container ViewControllers to customize how their children should adjust
/// their frame, content insets, or scroll indicator insets in relation to the keyboard.
///
/// An example scenario is when a ViewController has a UITableViewController child. That child
/// will have a zero `safeAreaInsets` value by default. If the keyboard is shown and the child
/// handles it by using `KeyboardScrollable`, there will be an extra space shown above the keyboard.
/// The table will only scroll up to that space, not up to the keyboard's top edge. To fix this,
/// the container ViewController can pass its `safeAreaInsets` like this:
///
/// ```
/// override func viewSafeAreaInsetsDidChange() {
///     super.viewSafeAreaInsetsDidChange()
///
///     children.compactMap {
///         $0 as? KeyboardFrameAdjustmentProvider
///     }.forEach {
///         $0.additionalKeyboardFrameHeight = 0 - view.safeAreaInsets.bottom
///     }
/// }
/// ```
///
/// The child UITableViewController can then simply use `KeyboardScrollable` to automatically
/// adjust the scrollable height when the keyboard is shown. The `additionalKeyboardFrameHeight`
/// will be automatically applied by `KeyboardScrollable`.
///
/// - SeeAlso: KeyboardScrollable
///
protocol KeyboardFrameAdjustmentProvider: UIViewController {
    /// The height that should be added to inset calculations.
    ///
    /// This is read-write because this will typically be adjusted by container ViewControllers.
    ///
    var additionalKeyboardFrameHeight: CGFloat { get set }
}
