import SwiftUI

/// Text field has a rounded border that has a thicker border and brighter border color when the field is focused.
public struct WooRoundedBorderTextFieldStyle: TextFieldStyle {
    private let focused: Bool
    private let focusedBorderColor: Color
    private let unfocusedBorderColor: Color
    private let backgroundColor: Color
    private let cornerRadius: CGFloat
    private let insets: EdgeInsets
    private let height: CGFloat?
    private let content: ((TextField<Self._Label>) -> AnyView)?

    /// - Parameters:
    ///   - focused: Whether the field is focused or not.
    ///   - focusedBorderColor: The border color when the field is focused.
    ///   - unfocusedBorderColor: The border color when the field is not focused.
    ///   - backgroundColor: The background color of the textfield
    ///   - insets: The insets between the background border and the text input.
    ///   - height: An optional fixed height for the field.
    ///   - content: Optional closure to wrap the text field content.
    public init(focused: Bool,
         focusedBorderColor: Color = Defaults.focusedBorderColor,
         unfocusedBorderColor: Color = Defaults.unfocusedBorderColor,
         backgroundColor: Color = .clear,
         cornerRadius: CGFloat = 8,
         insets: EdgeInsets = Defaults.insets,
         height: CGFloat? = nil,
         content: ((TextField<Self._Label>) -> AnyView)? = nil) {
        self.focused = focused
        self.focusedBorderColor = focusedBorderColor
        self.unfocusedBorderColor = unfocusedBorderColor
        self.cornerRadius = cornerRadius
        self.backgroundColor = backgroundColor
        self.insets = insets
        self.height = height
        self.content = content
    }

    public func _body(configuration: TextField<Self._Label>) -> some View {
        let styledContent = content?(configuration) ?? AnyView(configuration)

        styledContent
            .padding(insets)
            .background(
                backgroundColor
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                    .roundedBorder(cornerRadius: 8, lineColor: focused ? focusedBorderColor: unfocusedBorderColor,
                                   lineWidth: focused ? 2: 1)
                    .frame(height: height)
            )
            .frame(height: height)
    }
}

public extension WooRoundedBorderTextFieldStyle {
    enum Defaults {
        public static let focusedBorderColor: Color = .init(uiColor: .brand)
        public static let unfocusedBorderColor: Color = .gray
        public static let insets = EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
    }
}

struct TextFieldStyles_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            TextField("placeholder", text: .constant("focused"))
                .textFieldStyle(WooRoundedBorderTextFieldStyle(focused: true))
            TextField("placeholder", text: .constant("unfocused"))
                .textFieldStyle(WooRoundedBorderTextFieldStyle(focused: false))
            TextField("placeholder", text: .constant("focused with a different color"))
                .textFieldStyle(WooRoundedBorderTextFieldStyle(focused: true, focusedBorderColor: .orange))
                .environment(\.sizeCategory, .extraExtraExtraLarge)
            TextField("placeholder", text: .constant("unfocused with a different color"))
                .textFieldStyle(WooRoundedBorderTextFieldStyle(focused: false, unfocusedBorderColor: .cyan))
            TextField("placeholder", text: .constant("custom insets"))
                .textFieldStyle(WooRoundedBorderTextFieldStyle(focused: false, insets: .init(top: 20, leading: 0, bottom: 10, trailing: 50)))
                .frame(width: 150)
            HStack {
                TextField("placeholder", text: .constant("text field"))
                    .textFieldStyle(WooRoundedBorderTextFieldStyle(focused: true))
                SecureField("placeholder", text: .constant("secure"))
                    .textFieldStyle(WooRoundedBorderTextFieldStyle(focused: true))
            }
            .environment(\.sizeCategory, .extraExtraExtraLarge)
            HStack {
                TextField("placeholder", text: .constant("text field"))
                    .textFieldStyle(WooRoundedBorderTextFieldStyle(focused: true, height: 100))
                SecureField("placeholder", text: .constant("secure"))
                    .textFieldStyle(WooRoundedBorderTextFieldStyle(focused: true))
            }
            .environment(\.sizeCategory, .extraExtraExtraLarge)
        }
        .preferredColorScheme(.dark)
    }
}
