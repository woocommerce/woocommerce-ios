import SwiftUI

public extension View {
    /// Presents `content` in a ``StoreSheet`` while `isPresented` is `true`.
    ///
    /// The system sheet provides drag-to-dismiss, the dimmed backdrop and the detents; this styles it
    /// to the design (surface-bright container, extra-large top corners, the panel's own grabber in
    /// place of the system indicator) and sizes it per `sizing`.
    func storeSheet<Content: View>(isPresented: Binding<Bool>,
                                   sizing: StoreSheetSizing = .fitContent,
                                   onDismiss: (() -> Void)? = nil,
                                   @ViewBuilder content: @escaping () -> Content) -> some View {
        sheet(isPresented: isPresented, onDismiss: onDismiss) {
            StoreSheetPresentation(sizing: sizing, content: content)
        }
    }

    /// Presents `content` for `item` in a ``StoreSheet`` while `item` is non-`nil`.
    /// See `storeSheet(isPresented:sizing:onDismiss:content:)`.
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

/// The presented root: the panel pinned to the top of the sheet plus the presentation styling.
///
/// For `.fitContent` the content scrolls inside the panel, under the pinned grabber. The scroll view
/// offers it unbounded height, so the measurement is the content's ideal height rather than what the
/// opening detent would have squeezed it to, and content taller than the largest sheet (at large text
/// sizes, say) scrolls instead of being clipped.
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
                        // Explicit stack: a multi-view `content` would otherwise get the default spacing.
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
        .presentationDragIndicator(.hidden)
        .presentationBackground(Color.storeSurfaceBright)
        .presentationCornerRadius(StoreRadius.extraLarge)
    }

    /// `0` until the content has been measured, so the sheet opens at the placeholder detent.
    private var panelHeight: CGFloat {
        guard contentHeight > 0 else { return 0 }
        return StoreSheetLayout.panelHeight(contentHeight: contentHeight, safeAreaInset: bottomSafeAreaInset)
    }
}
