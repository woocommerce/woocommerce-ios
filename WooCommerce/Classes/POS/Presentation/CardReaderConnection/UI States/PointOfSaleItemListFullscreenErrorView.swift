import SwiftUI

/// A view that displays an error message with a retry CTA when the list of products fails to load.
struct PointOfSaleItemListFullscreenErrorView: View {
    private let error: PointOfSaleErrorState
    private let onAction: (() -> Void)?

    init(error: PointOfSaleErrorState, onAction: (() -> Void)? = nil) {
        self.error = error
        self.onAction = onAction
    }

    var body: some View {
        PointOfSaleItemListFullscreenView {
            PointOfSaleItemListErrorView(error: error, onAction: onAction)
        }
    }
}

#Preview {
    PointOfSaleItemListFullscreenErrorView(error: .errorOnLoadingProducts(), onAction: nil)
}
