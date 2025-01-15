import SwiftUI

/// A view that displays an error message with a retry CTA when the list of products fails to load.
struct PointOfSaleItemListFullscreenErrorView: View {
    private let error: PointOfSaleErrorState
    private let onRetry: (() -> Void)?

    init(error: PointOfSaleErrorState, onRetry: (() -> Void)? = nil) {
        self.error = error
        self.onRetry = onRetry
    }

    var body: some View {
        PointOfSaleItemListFullscreenView {
            PointOfSaleItemListErrorView(error: error, onRetry: onRetry)
        }
    }
}

#Preview {
    PointOfSaleItemListFullscreenErrorView(error: .errorOnLoadingProducts(), onRetry: nil)
}
