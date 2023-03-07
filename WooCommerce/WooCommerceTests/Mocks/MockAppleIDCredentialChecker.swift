@testable import WooCommerce

final class MockAppleIDCredentialChecker: AppleIDCredentialCheckerProtocol {
    private let hasAppleID: Bool

    init(hasAppleUserID: Bool) {
        self.hasAppleID = hasAppleUserID
    }

    func hasAppleUserID() -> Bool {
        hasAppleID
    }
}
