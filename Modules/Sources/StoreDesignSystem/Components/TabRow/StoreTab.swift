import SwiftUI

/// One tab of a ``StoreTabRow``: a label with an optional icon above it.
///
/// `Value` is the tab's identity, like a `Picker` tag, and should be unique within the row.
public struct StoreTab<Value: Hashable> {
    public let value: Value
    public let title: String
    public let icon: StoreIconImage?

    /// - Parameters:
    ///   - value: The tab's identity, matched against the row's `selection`.
    ///   - title: The tab's label, kept to a single line.
    ///   - icon: An optional icon shown above the label. Prefer giving every tab in a row an icon or
    ///     none; in a mixed row, text-only tabs reserve the icon's space so the labels still line up.
    public init(_ value: Value, title: String, icon: StoreIconImage? = nil) {
        self.value = value
        self.title = title
        self.icon = icon
    }
}

extension StoreTab: Sendable where Value: Sendable {}
