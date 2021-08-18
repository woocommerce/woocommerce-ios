import Foundation
import SwiftUI

/// Woo style modifiers.
/// Migrate them from `UILabel+Helpers` or  `UIButton+helpers` as needed.
///

// MARK: Woo Styles
struct BodyStyle: ViewModifier {
    /// Whether the View being modified is enabled
    ///
    var isEnabled: Bool

    func body(content: Content) -> some View {
        content
            .font(.body)
            .foregroundColor(isEnabled ? Color(.text) : Color(.textTertiary))
    }
}

struct SecondaryBodyStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.body)
            .foregroundColor(Color(.textSubtle))
    }
}

struct HeadlineStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.headline)
            .foregroundColor(Color(.text))
    }
}

struct SubheadlineStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.subheadline)
            .foregroundColor(Color(.textSubtle))
    }
}

struct FootnoteStyle: ViewModifier {
    /// Whether the View being modified is enabled
    ///
    var isEnabled: Bool

    func body(content: Content) -> some View {
        content
            .font(.footnote)
            .foregroundColor(isEnabled ? Color(.textSubtle) : Color(.textTertiary))
    }
}

struct ErrorStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.body)
            .foregroundColor(Color(.error))
    }
}

// MARK: View extensions
extension View {
    /// - Parameters:
    ///     - isEnabled: Whether the view is enabled (to apply specific styles for disabled view)
    func bodyStyle(_ isEnabled: Bool = true) -> some View {
        self.modifier(BodyStyle(isEnabled: isEnabled))
    }

    func secondaryBodyStyle() -> some View {
        self.modifier(SecondaryBodyStyle())
    }

    func headlineStyle() -> some View {
        self.modifier(HeadlineStyle())
    }

    func subheadlineStyle() -> some View {
        self.modifier(SubheadlineStyle())
    }

    /// - Parameters:
    ///     - isEnabled: Whether the view is enabled (to apply specific styles for disabled view)
    func footnoteStyle(_ isEnabled: Bool = true) -> some View {
        self.modifier(FootnoteStyle(isEnabled: isEnabled))
    }

    func errorStyle() -> some View {
        self.modifier(ErrorStyle())
    }
}
