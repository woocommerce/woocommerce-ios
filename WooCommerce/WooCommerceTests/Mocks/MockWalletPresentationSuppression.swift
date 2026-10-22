@testable import WooCommerce

@MainActor
final class MockWalletPresentationSuppression: WalletPresentationSuppressing {
    private(set) var suppressionRequestCount = 0
    private(set) var restorationCount = 0

    func suppressPresentation() {
        suppressionRequestCount += 1
    }

    func restorePresentation() {
        restorationCount += 1
    }
}
