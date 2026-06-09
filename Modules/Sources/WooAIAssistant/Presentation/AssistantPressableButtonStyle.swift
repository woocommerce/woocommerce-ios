import SwiftUI

public struct AssistantPressableButtonStyle: ButtonStyle {

    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? Layout.pressedOpacity : 1.0)
            .animation(.easeOut(duration: Layout.duration), value: configuration.isPressed)
    }

    private enum Layout {
        static let pressedOpacity: Double = 0.7
        static let duration: Double = 0.12
    }
}
