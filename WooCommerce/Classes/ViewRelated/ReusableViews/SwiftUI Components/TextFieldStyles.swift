import SwiftUI

/// Text field has a rounded border that has a thicker border and brighter border color when the field is focused.
struct RoundedBorderTextFieldStyle: TextFieldStyle {
    private let focused: Bool
    private let insets: EdgeInsets

    init(focused: Bool, insets: EdgeInsets = Defaults.insets) {
        self.focused = focused
        self.insets = insets
    }

    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(insets)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(focused ? Color(.brand): Color.gray,
                            lineWidth: focused ? 2: 1)
            )
    }
}

extension RoundedBorderTextFieldStyle {
    enum Defaults {
        static let insets = EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
    }
}
