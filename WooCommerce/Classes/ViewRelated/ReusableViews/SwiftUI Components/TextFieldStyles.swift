import SwiftUI

/// Text field has a rounded border that has a thicker border and brighter border color when the field is focused.
struct RoundedBorderTextFieldStyle: TextFieldStyle {
    let focused: Bool

    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(focused ? Color(.brand): Color.gray,
                            lineWidth: focused ? 2: 1)
            )
    }
}
