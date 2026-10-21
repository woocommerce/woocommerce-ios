import SwiftUI

/// A text field for filtering or discovering content: a magnifying glass, the query, a clear
/// control while the query is not empty, and an optional trailing text action such as Cancel, on
/// a surface-bright row.
///
/// - Note: The field owns no search logic. The host binds `text`, debounces and fetches, and
///   renders the results and empty states beneath it; a `.onSubmit` on the host catches the Search
///   key, and `.focused(_:)` / `.autocorrectionDisabled()` apply from outside as on any text
///   field. A tap anywhere on the field focuses it, as a `UISearchBar` does. The design's Resting
///   and Active states are driven by the text alone: the clear control appears with the first
///   character and only empties the query. Text and glyphs scale together under Dynamic Type up
///   to ``StoreDynamicTypeScaling/chromeMaximum``, the cap the top app bar uses, and the field grows with them.
public struct StoreSearchField: View {
    @Environment(\.isEnabled) private var isEnabled
    @FocusState private var isFieldFocused: Bool

    @Binding private var text: String
    private let placeholder: String
    private let trailingAction: StoreSearchFieldAction?

    /// - Parameters:
    ///   - text: The query. The field writes every keystroke and the clear control writes `""`.
    ///   - placeholder: Shown while the query is empty; also the field's VoiceOver label.
    ///   - trailingAction: The text action after the field, e.g. Cancel. `nil` lets the field fill the row.
    public init(text: Binding<String>,
                placeholder: String,
                trailingAction: StoreSearchFieldAction? = nil) {
        self._text = text
        self.placeholder = placeholder
        self.trailingAction = trailingAction
    }

    public var body: some View {
        HStack(spacing: StoreSpacing.s7) {
            field
            if let trailingAction {
                actionButton(trailingAction)
            }
        }
        .padding(.horizontal, StorePadding.p7)
        .padding(.vertical, StorePadding.p4)
        .background(appearance.container)
        .dynamicTypeSize(...StoreDynamicTypeScaling.chromeMaximum)
    }

    private var appearance: StoreSearchFieldAppearance {
        StoreSearchFieldAppearance(isEnabled: isEnabled)
    }

    // MARK: - Parts

    /// The rounded field. Its height is the design's 40 pt until larger text needs more. The whole
    /// pill is tappable: the text field alone would only focus from its own line box.
    private var field: some View {
        HStack(spacing: StoreSpacing.s4) {
            StoreIcon.MagnifyingGlass.regular.scaledImage(size: Constants.glassSize)
                .foregroundStyle(appearance.content)
                .accessibilityHidden(true)
            TextField(text: $text, prompt: prompt) {
                Text(placeholder)
            }
            .storeTextStyle(Constants.textStyle)
            .foregroundStyle(appearance.content)
            .focused($isFieldFocused)
            .submitLabel(.search)
            .accessibilityAddTraits(.isSearchField)
            if !text.isEmpty {
                StoreSearchFieldClearButton(text: $text, color: appearance.content)
            }
        }
        .padding(.horizontal, StorePadding.p5)
        .frame(minHeight: StoreSize.searchFieldHeight)
        .background(appearance.field, in: RoundedRectangle(cornerRadius: StoreRadius.large))
        .contentShape(Rectangle())
        .onTapGesture {
            isFieldFocused = true
        }
    }

    private var prompt: Text {
        Text(placeholder)
            .foregroundStyle(appearance.placeholder)
    }

    /// Matches the field's design height, as the design's `cancel` layer does, so the row stays 64 pt;
    /// the tap target overflows that frame to the HIG minimum, like the clear control's.
    private func actionButton(_ action: StoreSearchFieldAction) -> some View {
        Button(action: action.action) {
            Text(action.title)
                .storeTextStyle(Constants.actionTextStyle)
                .lineLimit(1)
                .foregroundStyle(actionColor(for: action))
                .frame(minWidth: StoreSize.minimumTapTarget, minHeight: StoreSize.minimumTapTarget)
                .contentShape(Rectangle())
        }
        .buttonStyle(StorePressFeedbackButtonStyle())
        .frame(height: StoreSize.searchFieldHeight)
        .disabled(!action.isEnabled)
    }

    private func actionColor(for action: StoreSearchFieldAction) -> Color {
        StoreSearchFieldAppearance(isEnabled: isEnabled && action.isEnabled).action
    }
}

private extension StoreSearchField {
    enum Constants {
        static let textStyle: StoreTextStyle = .bodyLarge
        static let actionTextStyle: StoreTextStyle = .labelLarge.emphasized
        static let glassSize: StoreIconSize = .medium
    }
}

/// The 16 pt glyph in layout, with a tap target extended to at least the HIG minimum around it:
/// the larger label overflows the glyph's frame without clipping, so it stays hittable while
/// the field keeps the design's inner padding. A view of its own so its scaled side is read
/// under the field's Dynamic Type cap and stops growing with the glyph. `CircleFull.solid` is
/// the icon set's x-in-a-filled-circle glyph (Figma "Solid/Circle Full"), despite its name.
private struct StoreSearchFieldClearButton: View {
    @Binding var text: String
    let color: Color
    @ScaledMetric private var side: CGFloat = Constants.size.value

    var body: some View {
        Button {
            text = ""
        } label: {
            StoreIcon.CircleFull.solid.scaledImage(size: Constants.size)
                .foregroundStyle(color)
                .frame(minWidth: StoreSize.minimumTapTarget, minHeight: StoreSize.minimumTapTarget)
                .contentShape(Rectangle())
        }
        .buttonStyle(StorePressFeedbackButtonStyle())
        .frame(width: side, height: side)
        .accessibilityLabel(Localization.clear)
    }

    private enum Constants {
        static let size: StoreIconSize = .small
    }

    private enum Localization {
        static let clear = NSLocalizedString(
            "storeSearchField.clear",
            value: "Clear",
            comment: "VoiceOver label of the control that empties the text of a search field."
        )
    }
}

#Preview("Light") {
    SearchFieldPreview()
}

#Preview("Dark") {
    SearchFieldPreview()
        .preferredColorScheme(.dark)
}

private struct SearchFieldPreview: View {
    @State private var resting = ""
    @State private var active = "Label"
    @State private var filter = ""
    @State private var disabled = "Label"

    var body: some View {
        VStack(spacing: StoreSpacing.s3) {
            StoreSearchField(text: $resting, placeholder: "Label", trailingAction: .init("Button") {})
            StoreSearchField(text: $active, placeholder: "Label", trailingAction: .init("Button") {})
            StoreSearchField(text: $filter, placeholder: "Filter without an action")
            StoreSearchField(text: $disabled, placeholder: "Label", trailingAction: .init("Button") {})
                .disabled(true)
        }
        .padding(.vertical, StorePadding.p5)
        .background(Color.storeSectionBackground)
    }
}
