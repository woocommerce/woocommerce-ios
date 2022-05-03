import SwiftUI

/// Renders a row with a label on the left side, and a text field on the right side, with eventually a symbol (like $)
///
struct TitleAndTextFieldRow: View {
    private let title: String
    private let placeholder: String
    private let symbol: String?
    private let keyboardType: UIKeyboardType
    private let onEditingChanged: ((Bool) -> Void)?
    private let editable: Bool
    private let fieldAlignment: TextAlignment
    private let accessibilityIdentifier: String?

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
         onEditingChanged: ((Bool) -> Void)? = nil,
         accessibilityIdentifier: String? = nil) {
        self.title = title
        self._titleWidth = titleWidth
        self.placeholder = placeholder
        self._text = text
        self.symbol = symbol
        self.editable = editable
        self.fieldAlignment = fieldAlignment
        self.keyboardType = keyboardType
        self.onEditingChanged = onEditingChanged
        self.accessibilityIdentifier = accessibilityIdentifier
    }

    var body: some View {
        AdaptiveStack(horizontalAlignment: .leading, spacing: Constants.spacing) {
            Text(title)
                .bodyStyle()
                .lineLimit(1)
                .fixedSize()
                .modifier(MaxWidthModifier())
                .frame(width: titleWidth, alignment: .leading)
            HStack {
                TextField(placeholder, text: $text, onEditingChanged: onEditingChanged ?? { _ in })
                    .multilineTextAlignment(fieldAlignment)
                    .font(.body)
                    .keyboardType(keyboardType)
                    .disabled(!editable)
                    //     .accessibilityIdentifier("test-accessibilityIdentifier-for-text-field")
                if let symbol = symbol {
                    Text(symbol)
                        .bodyStyle()
                }
            }
        }
        .frame(minHeight: Constants.height)
        .padding([.leading, .trailing], Constants.padding)
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
