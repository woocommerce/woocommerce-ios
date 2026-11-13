import SwiftUI

/// Renders a button as its plain label plus the module's press feedback — no button tint.
/// For components whose label already carries its own appearance (cell rows, icon controls).
struct StorePressFeedbackButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? Constants.pressedOpacity : 1)
            .animation(.easeOut(duration: StoreMotion.pressDuration), value: configuration.isPressed)
    }

    private enum Constants {
        static let pressedOpacity: Double = 0.7
    }
}
