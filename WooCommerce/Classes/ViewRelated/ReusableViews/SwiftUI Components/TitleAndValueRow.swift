import SwiftUI

/// Renders a row with a label on the left side, a value on the right side and a disclosure indicator if selectable
///
struct TitleAndValueRow: View {

    private let title: String
    private let value: Value
    private let bold: Bool
    private let selectable: Bool
    private let action: () -> Void

    init(title: String, value: Value, bold: Bool = false, selectable: Bool = false, action: @escaping () -> Void = {}) {
        self.title = title
        self.value = value
        self.bold = bold
        self.selectable = selectable
        self.action = action
    }

    var body: some View {
        Button(action: {
            action()
        }, label: {
            HStack {
                AdaptiveStack(horizontalAlignment: .leading) {
                    Text(title)
                        .style(bold: bold)
                        .multilineTextAlignment(.leading)

                    Text(value.text)
                        .style(for: value, bold: bold)
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .padding(.vertical, Constants.verticalPadding)
                }

                Image(uiImage: .chevronImage)
                    .flipsForRightToLeftLayoutDirection(true)
                    .renderedIf(selectable)
                    .frame(width: Constants.imageSize, height: Constants.imageSize)
                    .foregroundColor(Color(UIColor.gray(.shade30)))
            }
            .contentShape(Rectangle())
        })
        .disabled(!selectable)
        .frame(minHeight: Constants.minHeight)
        .padding(.horizontal, Constants.horizontalPadding)
        .accessibilityElement()
        .accessibilityLabel(Text(title))
        .accessibilityValue(Text(value.text))
        .accessibilityAddTraits(selectable ? .isButton : [])
    }
}

// MARK: Definitions
extension TitleAndValueRow {
    /// Type to differentiate what type of value we are supposed to render.
    ///
    enum Value {
        case placeholder(String)
        case content(String)

        var text: String {
            switch self {
            case .content(let value), .placeholder(let value):
                return value
            }
        }

        /// Returns `.content` if content is provided. Returns `.placeholder` otherwise.
        ///
        init (placeHolder: String, content: String?) {
            if let content = content, content.isNotEmpty {
                self = .content(content)
            } else {
                self = .placeholder(placeHolder)
            }
        }
    }
}

private extension Text {
    /// Styles the text based on the type of content.
    ///
    @ViewBuilder func style(for value: TitleAndValueRow.Value = .content(""), bold: Bool) -> some View {
        switch (value, bold) {
        case (.placeholder, _):
            self.modifier(SecondaryBodyStyle())
        case (.content, true):
            self.modifier(HeadlineStyle())
        case (.content, false):
            self.modifier(BodyStyle(isEnabled: true))
        }
    }
}

private extension TitleAndValueRow {
    enum Constants {
        static let imageSize: CGFloat = 22
        static let minHeight: CGFloat = 44
        static let maxHeight: CGFloat = 136
        static let horizontalPadding: CGFloat = 16
        static let verticalPadding: CGFloat = 12
    }
}

struct TitleAndValueRow_Previews: PreviewProvider {
    static var previews: some View {
        TitleAndValueRow(title: "Package selected", value: .placeholder("Small package 1"), selectable: true, action: { })
            .previewLayout(.fixed(width: 375, height: 100))
            .previewDisplayName("Row Selectable")

        TitleAndValueRow(title: "Package selected", value: .placeholder("Small package 2"), selectable: false, action: { })
            .previewLayout(.fixed(width: 375, height: 100))
            .previewDisplayName("Row Not Selectable")

        TitleAndValueRow(title: "This is a really long title which will take multiple lines",
                         value: .placeholder("This is a really long value which will take multiple lines"),
                         selectable: false,
                         action: { })
            .previewLayout(.fixed(width: 375, height: 150))
            .previewDisplayName("Long title and value")

        TitleAndValueRow(title: "Package selected", value: .placeholder("Small"), selectable: true, action: { })
            .environment(\.sizeCategory, .accessibilityExtraLarge)
            .previewLayout(.fixed(width: 375, height: 150))
            .previewDisplayName("Dynamic Type: Large Font Size")
    }
}
