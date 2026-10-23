import Foundation

/// The trailing text action of a ``StoreSearchField``, e.g. Cancel.
///
/// - Note: The design draws the action in both states and names its layer `cancel`. It is optional
///   here, as in Android's `WooSearchField`, so an always-on filter field can omit it. What the
///   action does — dismiss a modal search, leave a list's search mode — is the host's call; the
///   field never clears its text or resigns focus on its own.
public struct StoreSearchFieldAction {
    let title: String
    let isEnabled: Bool
    let action: () -> Void

    /// - Parameters:
    ///   - title: The visible, localized label, e.g. "Cancel". Single line.
    ///   - isEnabled: `false` dims the action and blocks it while the field stays usable.
    ///   - action: Runs on tap.
    public init(_ title: String, isEnabled: Bool = true, action: @escaping () -> Void) {
        self.title = title
        self.isEnabled = isEnabled
        self.action = action
    }
}
