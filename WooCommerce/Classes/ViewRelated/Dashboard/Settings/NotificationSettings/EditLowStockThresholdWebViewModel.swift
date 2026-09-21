import Foundation

/// `WPAdminWebViewModel` subclass that fires `onDisappear` when the
/// authenticated webview goes away, so the caller can refresh the cached
/// store-wide low-stock threshold.
///
final class EditLowStockThresholdWebViewModel: WPAdminWebViewModel {
    private let onDisappearHandler: () -> Void

    init(title: String, initialURL: URL, onDisappear: @escaping () -> Void) {
        self.onDisappearHandler = onDisappear
        super.init(title: title, initialURL: initialURL)
    }

    override func handleDisappear() {
        onDisappearHandler()
        super.handleDisappear()
    }
}
