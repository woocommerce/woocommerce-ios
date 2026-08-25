import SwiftUI
import UIKit

/// Replaces SwiftUI's built-in keyboard avoidance with an inset we compute from the keyboard notifications.
///
/// SwiftUI stops applying the keyboard safe area to the root of a sheet once a `NavigationStack` inside that sheet
/// has pushed and popped a destination while the keyboard was visible. From that point on, any bottom-pinned content
/// (for example a `safeAreaInset(edge: .bottom)` primary button) is laid out behind the keyboard, and the breakage
/// persists for the rest of the sheet's lifetime — even for a keyboard the user raises by tapping a field.
///
/// Applying this modifier opts the view out of SwiftUI's avoidance and pins the content above the keyboard using the
/// keyboard's own reported frame, which stays correct across navigation.
///
struct ManualKeyboardAvoidanceModifier: ViewModifier {
    /// Distance the content has to move up to clear the keyboard.
    ///
    @State private var keyboardOverlap: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .safeAreaInset(edge: .bottom, spacing: 0) {
                Color.clear.frame(height: keyboardOverlap)
            }
            .ignoresSafeArea(.keyboard, edges: .bottom)
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)) { notification in
                keyboardOverlap = Self.keyboardOverlap(from: notification)
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
                keyboardOverlap = 0
            }
    }
}

private extension ManualKeyboardAvoidanceModifier {
    /// How much of the window's content area the keyboard covers, ignoring the bottom safe area that the content already avoids.
    ///
    static func keyboardOverlap(from notification: Notification) -> CGFloat {
        guard let frameValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue,
              let window = keyWindow else {
            return 0
        }

        // The notification reports the frame in screen coordinates, which differ from the window's in Split View and Slide Over.
        let keyboardTop = window.convert(frameValue.cgRectValue, from: nil).minY
        let contentBottom = window.bounds.maxY - window.safeAreaInsets.bottom

        return max(0, contentBottom - keyboardTop)
    }

    static var keyWindow: UIWindow? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
    }
}

extension View {
    /// Pins bottom content above the keyboard without relying on SwiftUI's keyboard avoidance.
    /// See `ManualKeyboardAvoidanceModifier` for why this is needed.
    ///
    func manuallyAvoidingKeyboard() -> some View {
        modifier(ManualKeyboardAvoidanceModifier())
    }
}
