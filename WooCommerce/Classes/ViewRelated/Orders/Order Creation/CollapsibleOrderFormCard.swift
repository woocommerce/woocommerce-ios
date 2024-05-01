import SwiftUI
import Yosemite

/// A collapsible card that is shown in the order form, like the product card.
struct CollapsibleOrderFormCard<Label: View, Content: View>: View {
    private let hasSubtleChevron: Bool
    private let isCollapsed: Binding<Bool>
    private let showsBorder: Bool
    private let label: () -> Label
    private let content: () -> Content

    /// - Parameters:
    ///   - hasSubtleChevron: Whether a subtle up/down chevron icon is shown to indicate the card is collapsible.
    ///   - isCollapsed: Whether the card is collapsed.
    ///   - showsBorder: Whether the permanent card border is shown.
    ///   - label: View that is always shown in the collapsed and expanded states.
    ///   - content: View that is shown only when the card is expanded.
    init(hasSubtleChevron: Bool,
         isCollapsed: Binding<Bool>,
         showsBorder: Bool,
         @ViewBuilder label: @escaping () -> Label,
         @ViewBuilder content: @escaping () -> Content) {
        self.hasSubtleChevron = hasSubtleChevron
        self.isCollapsed = isCollapsed
        self.showsBorder = showsBorder
        self.label = label
        self.content = content
    }

    var body: some View {
        CollapsibleView<Label, Content>(isCollapsible: true,
                                        isCollapsed: isCollapsed,
                                        safeAreaInsets: EdgeInsets(),
                                        shouldShowDividers: false,
                                        hasSubtleChevron: hasSubtleChevron,
                                        label: label,
                                        content: content)
        .padding(Layout.padding)
        .frame(maxWidth: .infinity, alignment: .center)
        .background(Color(.listForeground(modal: false)))
        .overlay {
            CollapsibleOrderFormCardBorder(color: .init(uiColor: .text))
                .renderedIf(!isCollapsed.wrappedValue)
        }
        .overlay {
            cardBorder
                .renderedIf(showsBorder)
        }
    }

    var cardBorder: some View {
        CollapsibleOrderFormCardBorder(color: .init(uiColor: .separator))
    }
}

private enum Layout {
    static let padding: CGFloat = 16
}

#if DEBUG

/// A wrapper view for preview to enable passing the collapsed state.
struct CollapsibleOrderFormCardWrapperView<Label: View, Content: View>: View {
    @State private var isCollapsed: Bool = true
    private let hasSubtleChevron: Bool
    private let label: () -> Label
    private let content: () -> Content

    init(hasSubtleChevron: Bool,
         @ViewBuilder label: @escaping () -> Label,
         @ViewBuilder content: @escaping () -> Content) {
        self.hasSubtleChevron = hasSubtleChevron
        self.label = label
        self.content = content
    }

    var body: some View {
        CollapsibleOrderFormCard(hasSubtleChevron: hasSubtleChevron,
                                 isCollapsed: $isCollapsed,
                                 showsBorder: true,
                                 label: label,
                                 content: content)
    }
}

struct CollapsibleOrderFormCard_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            CollapsibleOrderFormCardWrapperView(hasSubtleChevron: true,
                                                label: {
                Text("Has subtle chevron")
            }, content: {
                Image(uiImage: .addOutlineImage)
            })
        }
        .padding()
    }
}

#endif
