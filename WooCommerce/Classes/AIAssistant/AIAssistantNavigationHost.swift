import UIKit

/// Stable handle on the chat's `UINavigationController` that survives across re-presentations.
/// Closures or static lookups would couple the navigation adaptor to the chat screen's lifecycle.
@MainActor
final class AIAssistantNavigationHost: @unchecked Sendable {
    weak var navigationController: UINavigationController?
}
