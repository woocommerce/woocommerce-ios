import SwiftUI
import UIKit

/// Owns the screen brightness, which UIKit only allows to change on the main actor.
///
/// No view reads its state, so it is held in `@State` only to keep one instance per view lifetime.
@MainActor
final class POSBrightnessControl {
    private var originalBrightness: CGFloat = 0.0
    private var isBrightnessIncreased: Bool = false

    init() {
        originalBrightness = UIScreen.main.brightness
    }

    func increaseBrightnessToMax() {
        guard !isBrightnessIncreased else { return }

        originalBrightness = UIScreen.main.brightness
        UIScreen.main.brightness = 1.0
        isBrightnessIncreased = true
    }

    func restoreOriginalBrightness() {
        guard isBrightnessIncreased else { return }

        UIScreen.main.brightness = originalBrightness
        isBrightnessIncreased = false
    }

    deinit {
        // `deinit` stays nonisolated until the deployment target allows `isolated deinit` (iOS 18.4),
        // so only the captured value is passed to the main actor.
        guard isBrightnessIncreased else { return }
        Task { @MainActor [originalBrightness] in
            UIScreen.main.brightness = originalBrightness
        }
    }
}

/// SwiftUI View Modifier for automatic brightness control
struct POSBrightnessControlModifier: ViewModifier {
    @State private var brightnessControl = POSBrightnessControl()

    func body(content: Content) -> some View {
        content
            .onAppear {
                brightnessControl.increaseBrightnessToMax()
            }
            .onDisappear {
                brightnessControl.restoreOriginalBrightness()
            }
    }
}

extension View {
    /// Applies brightness control to the view, increasing brightness to maximum when the view appears
    func maximumScreenBrightness() -> some View {
        modifier(POSBrightnessControlModifier())
    }
}
