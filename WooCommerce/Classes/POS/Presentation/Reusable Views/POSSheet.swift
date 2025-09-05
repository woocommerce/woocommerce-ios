import SwiftUI

//
// POSSheet - Wraps default SwiftUI .sheet() modifiers to support sheet presentation detection within POS.
//
// Usage: Replace .sheet() with .posSheet() and inject POSSheetManager at the POS root.
// Sheet presentation can be detected via POSSheetManager.isPresented.
//

// MARK: - Sheet Detection Infrastructure

final class POSSheetManager: ObservableObject {
    @Published private(set) var isPresented: Bool = false
    private var presentedSheets: Set<String> = []

    func registerSheetPresented(id: String) {
        presentedSheets.insert(id)
        updateState()
    }

    func registerSheetDismissed(id: String) {
        presentedSheets.remove(id)
        updateState()
    }

    private func updateState() {
        isPresented = !presentedSheets.isEmpty
    }
}

// MARK: - Individual Sheet Modifiers

struct POSSheetViewModifier<SheetContent: View>: ViewModifier {
    @EnvironmentObject var sheetManager: POSSheetManager
    @EnvironmentObject var coverManager: POSFullScreenCoverManager
    @Binding var isPresented: Bool
    let onDismiss: (() -> Void)?
    let sheetContent: () -> SheetContent

    @State private var sheetId = UUID().uuidString

    private var sheetIsPresented: Binding<Bool> {
        Binding<Bool>(get: {
            // Don't show a sheet if a full screen overlay is presented on top
            return self.$isPresented.wrappedValue && !coverManager.isPresented
        }, set: {
            self.$isPresented.wrappedValue = $0
        })
    }

    func body(content: Content) -> some View {
        content
            .sheet(isPresented: sheetIsPresented, onDismiss: onDismiss, content: sheetContent)
            .onChange(of: isPresented) { _, newValue in
                if newValue {
                    sheetManager.registerSheetPresented(id: sheetId)
                } else {
                    sheetManager.registerSheetDismissed(id: sheetId)
                }
            }
    }
}

struct POSSheetViewModifierForItem<Item: Identifiable & Equatable, SheetContent: View>: ViewModifier {
    @EnvironmentObject var sheetManager: POSSheetManager
    @EnvironmentObject var coverManager: POSFullScreenCoverManager
    @Binding var item: Item?
    let onDismiss: (() -> Void)?
    let sheetContent: (Item) -> SheetContent

    @State private var sheetId = UUID().uuidString

    private var sheetItem: Binding<Item?> {
        Binding<Item?>(get: {
            // Don't show a sheet if a full screen overlay is presented on top
            guard !coverManager.isPresented else { return nil }
            return self.$item.wrappedValue
        }, set: {
            self.$item.wrappedValue = $0
        })
    }

    func body(content: Content) -> some View {
        content
            .sheet(item: sheetItem, onDismiss: onDismiss, content: sheetContent)
            .onChange(of: sheetItem.wrappedValue) { _, newItem in
                let newValue = newItem != nil
                if newValue {
                    sheetManager.registerSheetPresented(id: sheetId)
                } else {
                    sheetManager.registerSheetDismissed(id: sheetId)
                }
            }
    }
}

// MARK: - View Modifiers

extension View {
    /// Shows a sheet with automatic detection of presentation.
    ///
    /// This works exactly like the native .sheet() modifier but automatically tracks
    /// presentation state.
    ///
    /// This will only work in a view hierarchy containing a `POSSheetManager` environment object.
    ///
    /// - Parameters:
    ///   - isPresented: Binding to control when the sheet is shown.
    ///   - onDismiss: Optional closure executed when the sheet is dismissed.
    ///   - content: Content to show in the sheet
    /// - Returns: a modified view which can show the sheet content specified, when applicable.
    func posSheet<SheetContent: View>(
        isPresented: Binding<Bool>,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> SheetContent
    ) -> some View {
        self.modifier(
            POSSheetViewModifier(
                isPresented: isPresented,
                onDismiss: onDismiss,
                sheetContent: content
            )
        )
    }

    /// Shows a sheet with automatic detection of presentation.
    ///
    /// This works exactly like the native .sheet(item:) modifier but automatically tracks
    /// presentation state.
    ///
    /// This will only work in a view hierarchy containing a `POSSheetManager` environment object.
    ///
    /// - Parameters:
    ///   - item: Binding to control when the sheet is shown. When non-nil, the item is used to build the content.
    ///   - onDismiss: Optional closure executed when the sheet is dismissed.
    ///   - content: Content to show in the sheet
    /// - Returns: a modified view which can show the sheet content specified, when applicable.
    func posSheet<Item: Identifiable & Equatable, SheetContent: View>(
        item: Binding<Item?>,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping (Item) -> SheetContent
    ) -> some View {
        self.modifier(
            POSSheetViewModifierForItem(
                item: item,
                onDismiss: onDismiss,
                sheetContent: content
            )
        )
    }
}
