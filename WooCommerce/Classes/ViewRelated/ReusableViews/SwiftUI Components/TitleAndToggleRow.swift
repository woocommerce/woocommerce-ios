import SwiftUI

/// Renders a row with a label on the left side, and a toggle switch on the right side
///
struct TitleAndToggleRow: View {
    let title: String
    let isSubheadline: Bool
    @Binding var isOn: Bool
    @Environment(\.isEnabled) var isEnabled

    init(title: String, isSubheadline: Bool = false, isOn: Binding<Bool>) {
        self.title = title
        self.isSubheadline = isSubheadline
        self._isOn = isOn
    }

    var body: some View {
        toggle
            .toggleStyle(SwitchToggleStyle.init(tint: isEnabled ? Color(.primary) : Color(.switchDisabledColor)))
            .fixedSize(horizontal: false, vertical: true)
    }

    private var toggle: some View {
        Group {
            if isSubheadline {
                Toggle(title, isOn: $isOn)
                    .font(.subheadline)
                    .foregroundColor(isEnabled ? Color(.text) : Color(.textSubtle))
            } else {
                Toggle(title, isOn: $isOn)
                    .bodyStyle(isEnabled)
            }
        }
    }
}

private extension TitleAndToggleRow {
    enum Constants {
        static let padding: CGFloat = 16
    }
}

struct TitleAndToggleRow_Previews: PreviewProvider {
    static var previews: some View {
        TitleAndToggleRow(title: "Toggle this setting", isOn: .constant(false))
            .previewLayout(.sizeThatFits)
            .previewDisplayName("Single line, toggle off")

        TitleAndToggleRow(title: "Toggle this setting", isOn: .constant(true))
            .disabled(true)
            .previewLayout(.sizeThatFits)
            .previewDisplayName("Disabled state")

        TitleAndToggleRow(title: "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Maecenas dictum ullamcorper enim.", isOn: .constant(true))
            .previewLayout(.sizeThatFits)
            .previewDisplayName("Multi-line, toggle on")

        TitleAndToggleRow(title: "Toggle this setting", isOn: .constant(true))
            .previewLayout(.sizeThatFits)
            .environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge)
            .previewDisplayName("Accessibility: Large Font Size")

        TitleAndToggleRow(title: "Toggle this setting", isOn: .constant(true))
            .previewLayout(.sizeThatFits)
            .environment(\.layoutDirection, .rightToLeft)
            .previewDisplayName("Localization: Right-to-Left Layout")
    }
}
