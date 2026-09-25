import SwiftUI

public extension View {
    /// Presents `content` in a ``StoreSheet`` while `isPresented` is `true`: the system sheet styled to
    /// the design (surface-bright container, extra-large top corners) and sized per `sizing`.
    func storeSheet<Content: View>(isPresented: Binding<Bool>,
                                   sizing: StoreSheetSizing = .fitContent,
                                   onDismiss: (() -> Void)? = nil,
                                   @ViewBuilder content: @escaping () -> Content) -> some View {
        sheet(isPresented: isPresented, onDismiss: onDismiss) {
            StoreSheetPresentation(sizing: sizing, content: content)
        }
    }

    /// Presents `content` for `item` in a ``StoreSheet`` while `item` is non-`nil`.
    func storeSheet<Item: Identifiable, Content: View>(item: Binding<Item?>,
                                                        sizing: StoreSheetSizing = .fitContent,
                                                        onDismiss: (() -> Void)? = nil,
                                                        @ViewBuilder content: @escaping (Item) -> Content) -> some View {
        sheet(item: item, onDismiss: onDismiss) { item in
            StoreSheetPresentation(sizing: sizing) {
                content(item)
            }
        }
    }
}

/// The presented root. For `.fitContent` the content sits in a scroll view, so it is measured at its
/// ideal height (not squeezed by the opening detent) and scrolls when taller than the largest sheet.
private struct StoreSheetPresentation<Content: View>: View {
    let sizing: StoreSheetSizing
    @ViewBuilder let content: () -> Content

    @State private var contentHeight: CGFloat = 0
    @State private var bottomSafeAreaInset: CGFloat = 0

    var body: some View {
        Group {
            if sizing == .fitContent {
                StoreSheet {
                    ScrollView {
                        VStack(spacing: StoreSpacing.s0) {
                            content()
                        }
                        .onGeometryChange(for: CGFloat.self, of: { $0.size.height }) { height in
                            contentHeight = height
                        }
                    }
                    .scrollBounceBehavior(.basedOnSize)
                }
                .onGeometryChange(for: CGFloat.self, of: { $0.safeAreaInsets.bottom }) { inset in
                    bottomSafeAreaInset = inset
                }
            } else {
                StoreSheet(content: content)
                    .frame(maxHeight: .infinity, alignment: .top)
            }
        }
        .presentationDetents(sizing.detents(panelHeight: panelHeight))
        .presentationDragIndicator(.visible)
        .presentationBackground(Color.storeSurfaceBright)
        .presentationCornerRadius(StoreRadius.extraLarge)
    }

    private var panelHeight: CGFloat {
        guard contentHeight > 0 else { return 0 }
        return StoreSheetLayout.panelHeight(contentHeight: contentHeight, safeAreaInset: bottomSafeAreaInset)
    }
}
