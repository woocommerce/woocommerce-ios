import SwiftUI

/// Text field has a rounded border that has a thicker border and brighter border color when the field is focused.
struct RoundedBorderTextFieldStyle: TextFieldStyle {
    private let focused: Bool
    private let focusedBorderColor: Color
    private let unfocusedBorderColor: Color

    init(focused: Bool,
         focusedBorderColor: Color = Defaults.focusedBorderColor,
         unfocusedBorderColor: Color = Defaults.unfocusedBorderColor) {
        self.focused = focused
        self.focusedBorderColor = focusedBorderColor
        self.unfocusedBorderColor = unfocusedBorderColor
    }

    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(focused ? focusedBorderColor: unfocusedBorderColor,
                            lineWidth: focused ? 2: 1)
            )
    }
}

extension RoundedBorderTextFieldStyle {
    enum Defaults {
        static let focusedBorderColor: Color = .init(uiColor: .brand)
        static let unfocusedBorderColor: Color = .gray
    }
}

struct TextFieldStyles_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            TextField("placeholder", text: .constant("focused"))
                .textFieldStyle(RoundedBorderTextFieldStyle(focused: true))
            TextField("placeholder", text: .constant("unfocused"))
                .textFieldStyle(RoundedBorderTextFieldStyle(focused: false))
            TextField("placeholder", text: .constant("focused with a different color"))
                .textFieldStyle(RoundedBorderTextFieldStyle(focused: true, focusedBorderColor: .orange))
            TextField("placeholder", text: .constant("unfocused with a different color"))
                .textFieldStyle(RoundedBorderTextFieldStyle(focused: false, unfocusedBorderColor: .cyan))
        }
        .preferredColorScheme(.dark)
    }
}
