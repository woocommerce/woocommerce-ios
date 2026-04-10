import SwiftUI
import UIKit

@Observable
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
        if isBrightnessIncreased {
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
