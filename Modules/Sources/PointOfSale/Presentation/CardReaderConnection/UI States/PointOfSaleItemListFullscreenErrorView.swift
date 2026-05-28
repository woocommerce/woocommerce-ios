import SwiftUI

/// A view that displays an error message with a retry CTA when the list of products fails to load.
struct PointOfSaleItemListFullscreenErrorView: View {
    private let error: PointOfSaleErrorState
    private let onAction: (() -> Void)?
    private let onExit: (() -> Void)?

    init(error: PointOfSaleErrorState, onAction: (() -> Void)? = nil, onExit: (() -> Void)? = nil) {
        self.error = error
        self.onAction = onAction
        self.onExit = onExit
    }

    var body: some View {
        PointOfSaleItemListFullscreenView(showTitle: !hidesItemListTitle) {
            POSListErrorView(error: error, onAction: onAction, onExit: onExit)
        }
    }

    /// Errors that aren't about the items list itself shouldn't render the items-list title
    /// (catalog sync is the original case; staff load errors join it because they're a
    /// startup-time concern, not an items concern).
    /// TODO: WOOMOB-1692 remove specialisation of errors if possible
    private var hidesItemListTitle: Bool {
        switch error.errorType {
        case .initialCatalogSyncError, .staffLoadError: true
        default: false
        }
    }
}

#Preview {
    PointOfSaleItemListFullscreenErrorView(error: .errorOnLoadingProducts(), onAction: nil)
}
