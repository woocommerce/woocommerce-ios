import Foundation
import SwiftUI
import Testing
import WebKit
@testable import WooCommerce

@MainActor
struct WebViewCoordinatorIsolationTests {
    @Test
    func test_coordinator_when_created_then_exports_navigation_policy_callback() throws {
        // Given
        let url = try #require(URL(string: "about:blank"))
        let view = WebView(isPresented: .constant(true), url: url, disableLinkClicking: true)

        // When
        let coordinator = view.makeCoordinator()
        let selector = NSSelectorFromString("webView:decidePolicyForNavigationAction:decisionHandler:")

        // Then
        #expect(coordinator.responds(to: selector))
    }
}
