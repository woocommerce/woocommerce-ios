import SwiftUI

/// Environment key that allow use to obtain safe areas insets from a environment value.
/// By `default` it provides the first window safe areas insets.
/// Provide your custom inset with  the `environment(_:_:)` modifier when dealing with multiple windows or specific screens.
///
struct SafeAreaInsetsKey: EnvironmentKey {
    /// Returns the safe areas of the main window.
    ///
    static var defaultValue: EdgeInsets {
        guard let window = UIApplication.shared.windows.first else {
            return .zero
        }

        // Converts the non-directional UIEdgeInstets into directional EdgeInsets
        let safeInsets = window.safeAreaInsets
        if UIView.userInterfaceLayoutDirection(for: window.semanticContentAttribute) == .rightToLeft {
            return EdgeInsets(top: safeInsets.top, leading: safeInsets.right, bottom: safeInsets.bottom, trailing: safeInsets.left)
        } else {
            return EdgeInsets(top: safeInsets.top, leading: safeInsets.left, bottom: safeInsets.bottom, trailing: safeInsets.right)
        }
    }
}

extension EnvironmentValues {
    /// Sets a custom safe area inset.
    ///
    var safeAreaInsets: EdgeInsets {
        get {
            self[SafeAreaInsetsKey.self]
        }
        set {
            self[SafeAreaInsetsKey.self] = newValue
        }
    }
}
