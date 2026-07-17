import SwiftUI

/// A group of mutually exclusive radio options bound to a `selection`.
///
/// Owns the exclusive selection: tapping a row sets `selection` to that option's value. Each row pairs
/// the radio with caller-provided content — any view, vertically centered against the radio.
/// `.disabled(_:)` on the group disables every row.
public struct StoreRadioGroup<Value: Hashable, Content: View>: View {
    @Binding private var selection: Value
    private let options: [Value]
    private let rowSpacing: CGFloat
    private let content: (Value) -> Content

    /// - Parameters:
    ///   - selection: the currently selected value.
    ///   - options: the values to offer, in display order. Must be unique.
    ///   - rowSpacing: the vertical gap between rows. Defaults to `StoreSpacing.s5`.
    ///   - content: the content for a given value.
    public init(selection: Binding<Value>,
                options: [Value],
                rowSpacing: CGFloat = StoreSpacing.s5,
                @ViewBuilder content: @escaping (Value) -> Content) {
        assert(Set(options).count == options.count,
               "StoreRadioGroup requires unique options; duplicates break row identity and shared selection.")
        self._selection = selection
        self.options = options
        self.rowSpacing = rowSpacing
        self.content = content
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: rowSpacing) {
            ForEach(options, id: \.self) { option in
                row(for: option)
            }
        }
    }

    private func row(for option: Value) -> some View {
        Button {
            selection = option
        } label: {
            HStack(alignment: .center, spacing: Layout.contentSpacing) {
                StoreRadioButtonIndicator(isSelected: selection == option)
                    .accessibilityHidden(true)
                content(option)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(minHeight: StoreSize.minimumTapTarget)
            .contentShape(Rectangle())
        }
        .buttonStyle(StoreRadioRowStyle())
        .accessibilityValue(StoreRadioRowAccessibility.value(isSelected: selection == option))
    }
}

private enum Layout {
    /// The gap between the radio and its content — a fixed part of the row, not caller-configurable.
    static let contentSpacing = StoreSpacing.s4
}

/// Renders a selectable row as its plain content plus the press feedback — no button tint.
private struct StoreRadioRowStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? Constants.pressedOpacity : 1)
            .animation(.easeOut(duration: Constants.animationDuration), value: configuration.isPressed)
    }

    private enum Constants {
        static let pressedOpacity: Double = 0.7
        static let animationDuration: TimeInterval = 0.15
    }
}

/// The VoiceOver value announced for a row's selection state, so it reads in every case (not just
/// when selected).
private enum StoreRadioRowAccessibility {
    static func value(isSelected: Bool) -> String {
        isSelected ? selected : unselected
    }

    private static let selected = NSLocalizedString(
        "storeRadioButton.accessibilityValue.selected",
        value: "Selected",
        comment: "VoiceOver value announced for a selected radio button."
    )
    private static let unselected = NSLocalizedString(
        "storeRadioButton.accessibilityValue.unselected",
        value: "Unselected",
        comment: "VoiceOver value announced for an unselected radio button."
    )
}
