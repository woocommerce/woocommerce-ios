import Foundation

/// Conformance to display SwiftUI sheet based on a URL.
extension URL: Identifiable {
    public var id: String { absoluteString }
}
