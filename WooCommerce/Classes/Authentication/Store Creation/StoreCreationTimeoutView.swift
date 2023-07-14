import SwiftUI

/// Hosting controller for `StoreCreationTimeoutView`.
///
final class StoreCreationTimeoutHostingController: UIHostingController<StoreCreationTimeoutView> {
    init(onRetry: @escaping () async -> Void) {
        super.init(rootView: StoreCreationTimeoutView(onRetry: onRetry))
    }

    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// View displayed upon timeout checking store for store creation.
///
struct StoreCreationTimeoutView: View {
    private let onRetry: () async -> Void
    @State private var isRetrying: Bool = false

    init(onRetry: @escaping () async -> Void) {
        self.onRetry = onRetry
    }

    var body: some View {
        VStack(spacing: Layout.verticalSpacing) {
            Text(Localization.title)
                .headlineStyle()
            Image(uiImage: .noStoreImage)
            Text(Localization.message)
                .bodyStyle()
            Button(Localization.retryActionTitle) {
                Task { @MainActor in
                    isRetrying = true
                    await onRetry()
                    isRetrying = false
                }
            }
            .buttonStyle(PrimaryLoadingButtonStyle(isLoading: isRetrying))
        }
        .padding(.horizontal, Layout.horizontalMargin)
    }
}

private extension StoreCreationTimeoutView {
    enum Layout {
        static let horizontalMargin: CGFloat = 32
        static let verticalSpacing: CGFloat = 16
    }
    enum Localization {
        static let title = NSLocalizedString(
            "Store creation still in progress",
            comment: "Title of the screen when the created store never becomes a Jetpack site in the store creation flow."
        )
        static let message = NSLocalizedString(
            "The new store will be available soon in the store picker. Please wait a bit and try again.",
            comment: "Message of the screen when the created store never becomes a Jetpack site in the store creation flow."
        )
        static let retryActionTitle = NSLocalizedString(
            "Retry",
            comment: "Button title to retry checking for store details after store creation."
        )
    }
}

struct StoreCreationTimeoutView_Previews: PreviewProvider {
    static var previews: some View {
        StoreCreationTimeoutView(onRetry: {})
    }
}
