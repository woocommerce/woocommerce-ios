import Foundation

/// Provides access to the JSON response fixtures previously bundled
/// directly in `NetworkingTests/Responses`.
///
/// Any test target that needs these fixtures should depend on this
/// target. The resource bundle is then discoverable via
/// `Bundle.allBundles`, so existing `Loader.contentsOf(_:)` call
/// sites continue to work without changes.
public enum NetworkingTestsResponsesFixtures {
    /// The resource bundle containing the JSON response fixtures.
    public static let bundle: Bundle = .module
}
