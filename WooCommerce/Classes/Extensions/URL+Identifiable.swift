import Foundation

/// Conformance to display SwiftUI sheet based on a URL.
///
/// The `@retroactive` attribute is used to apply `Identifiable` to `URL` from the Foundation module.
/// This is necessary due to Swift 6 [SE-0364 proposal](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0364-retroactive-conformance-warning.md).
extension URL: @retroactive Identifiable {
    public var id: String { absoluteString }
}
