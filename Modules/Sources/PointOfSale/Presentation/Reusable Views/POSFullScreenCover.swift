import SwiftUI

extension View {
    /// Shows a full screen cover that automatically manages modal hierarchy.
    /// This is a wrapper around SwiftUI's fullScreenCover that integrates with POS modal system.
    ///
    /// Full screen covers automatically establish a new presentation layer, so:
    /// - Modals/sheets from views behind the cover will not show
    /// - Modals/sheet within the cover content will show normally
    /// - Multiple covers can be stacked with proper hierarchy management
    ///
    /// - Parameters:
    ///   - isPresented: Binding to control when the full screen cover is shown
    ///   - onDismiss: Optional closure called when the cover is dismissed
    ///   - content: Content to show in full screen
    /// - Returns: a modified view that shows full screen content with automatic modal hierarchy
    // periphery:ignore
    func posFullScreenCover<Content: View>(
        isPresented: Binding<Bool>,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        self.modifier(
            POSFullScreenCoverModifier(
                isPresented: isPresented,
                onDismiss: onDismiss,
                coverContent: content
            )
        )
    }

    /// - Parameters:
    ///   - item: Binding to control when the full screen cover is shown
    ///   - onDismiss: Optional closure called when the cover is dismissed
    ///   - content: Content to show in full screen
    /// - Returns: a modified view that shows full screen content with automatic modal hierarchy
    // periphery:ignore
    func posFullScreenCover<Item: Identifiable & Equatable, Content: View>(
        item: Binding<Item?>,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping (Item) -> Content
    ) -> some View {
        self.modifier(
            POSFullScreenCoverModifierForItem(
                item: item,
                onDismiss: onDismiss,
                coverContent: content
            )
        )
    }
}

final class POSFullScreenCoverManager: ObservableObject {
    @Published fileprivate(set) var isPresented: Bool = false

    func clearPresentation() {
        isPresented = false
    }
}

// MARK: - Modifiers
// periphery:ignore
struct POSFullScreenCoverModifier<CoverContent: View>: ViewModifier {
    @Environment(\.posAccessSession) private var session
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Binding var isPresented: Bool
    let onDismiss: (() -> Void)?
    let coverContent: () -> CoverContent

    @EnvironmentObject var parentCoverManager: POSFullScreenCoverManager
    @StateObject private var modalManager = POSModalManager()
    @StateObject private var sheetManager = POSSheetManager()
    @StateObject private var coverManager = POSFullScreenCoverManager()
    @State private var dismissal = POSNativePresentationDismissal()

    func body(content: Content) -> some View {
        let activePresentation = Binding(get: { !session.isLocked && isPresented }, set: { isPresented = $0 })
        content
            .posDismissOnLock($isPresented, to: false, when: session.isLocked)
            .fullScreenCover(isPresented: activePresentation, onDismiss: {
                modalManager.onDisappear()
                dismissal.takeAction(in: session, action: onDismiss)?()
            }, content: {
                coverContent()
                    .onAppear {
                        dismissal.presented(in: session)
                        parentCoverManager.isPresented = true
                    }
                    .environment(\.horizontalSizeClass, horizontalSizeClass)
                    .posRootModal()
                    .environment(\.posHeaderBackButtonConfiguration, nil)
                    .environmentObject(modalManager)
                    .environmentObject(sheetManager)
                    .environmentObject(coverManager)
            })
            .onChange(of: isPresented) { _, newValue in
                parentCoverManager.isPresented = newValue
            }
    }
}
// periphery:ignore
struct POSFullScreenCoverModifierForItem<Item: Identifiable & Equatable, CoverContent: View>: ViewModifier {
    @Environment(\.posAccessSession) private var session
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Binding var item: Item?
    let onDismiss: (() -> Void)?
    let coverContent: (Item) -> CoverContent

    @EnvironmentObject var parentCoverManager: POSFullScreenCoverManager
    @StateObject private var modalManager = POSModalManager()
    @StateObject private var sheetManager = POSSheetManager()
    @StateObject private var coverManager = POSFullScreenCoverManager()
    @State private var dismissal = POSNativePresentationDismissal()

    func body(content: Content) -> some View {
        let activePresentation = Binding(get: { session.isLocked ? nil : item }, set: { item = $0 })
        content
            .posDismissOnLock($item, to: nil, when: session.isLocked)
            .fullScreenCover(item: activePresentation, onDismiss: {
                modalManager.onDisappear()
                dismissal.takeAction(in: session, action: onDismiss)?()
            }, content: {
                coverContent($0)
                    .onAppear {
                        dismissal.presented(in: session)
                        parentCoverManager.isPresented = true
                    }
                    .environment(\.horizontalSizeClass, horizontalSizeClass)
                    .posRootModal()
                    .environment(\.posHeaderBackButtonConfiguration, nil)
                    .environmentObject(modalManager)
                    .environmentObject(sheetManager)
                    .environmentObject(coverManager)
            })
            .onChange(of: item) { _, newValue in
                parentCoverManager.isPresented = newValue != nil
            }
    }
}
