import SwiftUI

/// Environment key for the safe-area insets of the container a screen is laid out in.
///
/// Read a live value at the screen root with `SafeAreaInsetsReader`.
/// The default reads the first window once and never updates; it is a fallback being phased out (WOOMOB-4063).
///
struct SafeAreaInsetsKey: EnvironmentKey {
    /// Returns the safe areas of the main window.
    ///
    static var defaultValue: EdgeInsets {

        // Get the first window from all connected scenes
        let scenes = UIApplication.shared.connectedScenes
        guard let window = scenes.compactMap({ $0 as? UIWindowScene }).flatMap({ $0.windows }).first else {
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

/// Reads the safe-area insets of the container this view is laid out in and hands them to `content`.
/// Place it at a screen root, outside any `ScrollView`: inside scroll content there is no safe area left to read.
/// It also publishes the value as `EnvironmentValues.safeAreaInsets` for shared components that read it themselves.
///
struct SafeAreaInsetsReader<Content: View>: View {
    @ViewBuilder let content: (EdgeInsets) -> Content

    var body: some View {
        GeometryReader { geometry in
            content(geometry.safeAreaInsets)
                .environment(\.safeAreaInsets, geometry.safeAreaInsets)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
