
import SwiftUI

struct POSTextButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.posBodyRegular)
            .contentShape(Rectangle())
            .foregroundColor(foregroundColor(for: configuration))
            .background(Color(.clear))
    }

    private func foregroundColor(for configuration: Configuration) -> Color {
        if isEnabled {
            return configuration.isPressed ? .posTextButtonForegroundPressed : .posTextButtonForeground
        } else {
            return .posTextButtonDisabled
        }
    }
}
