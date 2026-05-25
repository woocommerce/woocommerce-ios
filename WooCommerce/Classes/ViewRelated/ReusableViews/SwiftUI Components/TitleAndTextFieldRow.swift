import SwiftUI

/// Renders a row with a label on the left side, and a text field on the right side, with eventually a symbol (like $)
///
struct TitleAndTextFieldRow: View {
    private let title: String
    private let placeholder: String
    private let symbol: String?
    private let keyboardType: UIKeyboardType
    private let autocapitalization: TextInputAutocapitalization
    private let onEditingChanged: ((Bool) -> Void)?
    private let editable: Bool
    private let fieldAlignment: TextAlignment
    private let inputFormatter: UnitInputFormatter?
    private let titleColor: Color
    private let titleFont: Font
    private let valueColor: Color
    private let valueFont: Font
    private let minHeight: CGFloat
    private let horizontalPadding: CGFloat

    @Binding private var text: String

    /// Static width for title label. Used to align values between different rows.
    /// If `nil` - title will have intrinsic size.
    ///
    @Binding private var titleWidth: CGFloat?


    init(title: String,
         titleWidth: Binding<CGFloat?> = .constant(nil),
         placeholder: String,
         text: Binding<String>,
         symbol: String? = nil,
         editable: Bool = true,
         fieldAlignment: TextAlignment = .trailing,
         keyboardType: UIKeyboardType = .default,
         autocapitalization: TextInputAutocapitalization = .sentences,
         titleColor: Color = Color(.label),
         titleFont: Font = .body,
         valueColor: Color = Color(.label),
         valueFont: Font = .body,
         inputFormatter: UnitInputFormatter? = nil,
         minHeight: CGFloat = Constants.height,
         horizontalPadding: CGFloat = Constants.padding,
         onEditingChanged: ((Bool) -> Void)? = nil) {
        self.title = title
        self._titleWidth = titleWidth
        self.placeholder = placeholder
        self._text = text
        self.symbol = symbol
        self.editable = editable
        self.fieldAlignment = fieldAlignment
        self.keyboardType = keyboardType
        self.autocapitalization = autocapitalization
        self.titleColor = titleColor
        self.titleFont = titleFont
        self.valueColor = valueColor
        self.valueFont = valueFont
        self.inputFormatter = inputFormatter
        self.minHeight = minHeight
        self.horizontalPadding = horizontalPadding
        self.onEditingChanged = onEditingChanged
    }

    var body: some View {
        AdaptiveStack(horizontalAlignment: .leading, spacing: Constants.spacing) {
            Text(title)
                .foregroundColor(titleColor)
                .lineLimit(1)
                .font(titleFont)
                .fixedSize()
                .modifier(MaxWidthModifier())
                .frame(width: titleWidth, alignment: .leading)
            HStack {
                TextField(placeholder, text: $text, onEditingChanged: onEditingChanged ?? { _ in })
                    .foregroundColor(valueColor)
                    .onChange(of: text) { _, newValue in
                        text = formatText(newValue)
                    }
                    .onAppear {
                        text = formatText(text)
                    }
                    .multilineTextAlignment(fieldAlignment)
                    .font(valueFont)
                    .keyboardType(keyboardType)
                    .disabled(!editable)
                    .textInputAutocapitalization(autocapitalization)
                if let symbol {
                    Text(symbol)
                        .bodyStyle()
                        .font(valueFont)
                        .foregroundColor(valueColor)
                }
            }
        }
        .frame(minHeight: minHeight)
        .padding([.leading, .trailing], horizontalPadding)
    }

    private func formatText(_ newValue: String) -> String {
        guard let inputFormatter else {
            return newValue
        }
        return inputFormatter.format(input: newValue)
    }
}

private extension TitleAndTextFieldRow {
    enum Constants {
        static let height: CGFloat = 44
        static let padding: CGFloat = 16
        static let spacing: CGFloat = 20
    }
}

struct TitleAndTextFieldRow_Previews: PreviewProvider {
    static var previews: some View {
        TitleAndTextFieldRow(title: "Add your text",
                             placeholder: "Start typing",
                             text: .constant(""),
                             symbol: nil,
                             keyboardType: .default)
            .previewLayout(.fixed(width: 375, height: 100))
            .previewDisplayName("No text")

        TitleAndTextFieldRow(title: "Add your text",
                             placeholder: "Start typing",
                             text: .constant("Hello"),
                             symbol: nil,
                             keyboardType: .default)
            .previewLayout(.fixed(width: 375, height: 100))
            .previewDisplayName("With text")

        TitleAndTextFieldRow(title: "Total package weight",
                             placeholder: "Value",
                             text: .constant(""),
                             symbol: "oz",
                             keyboardType: .default)
            .previewLayout(.fixed(width: 375, height: 100))
            .previewDisplayName("With symbol")

        TitleAndTextFieldRow(title: "Add your text",
                             placeholder: "Start typing",
                             text: .constant("Hello"),
                             symbol: nil,
                             keyboardType: .default)
            .environment(\.sizeCategory, .accessibilityExtraLarge)
            .previewLayout(.fixed(width: 375, height: 150))
            .previewDisplayName("Dynamic Type: Large Font Size")

        TitleAndTextFieldRow(title: "Total package weight",
                             placeholder: "Value",
                             text: .constant(""),
                             symbol: "oz",
                             keyboardType: .default)
            .environment(\.sizeCategory, .accessibilityExtraLarge)
            .previewLayout(.fixed(width: 375, height: 150))
            .previewDisplayName("Dynamic Type: Large Font Size with symbol")

        TitleAndTextFieldRow(title: "Total package weight",
                             placeholder: "Value",
                             text: .constant(""),
                             symbol: "oz",
                             fieldAlignment: .leading,
                             keyboardType: .default)
            .previewLayout(.fixed(width: 375, height: 150))
            .previewDisplayName("With leading alignment")
    }
}
