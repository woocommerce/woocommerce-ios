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


struct LargeTitleStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.largeTitle)
            .foregroundColor(Color(.text))
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

    /// Whether the View shows error state
    ///
    var isError: Bool

    func body(content: Content) -> some View {
        content
            .font(.footnote)
            .foregroundColor(textColor)
    }

    private var textColor: Color {
        switch (isEnabled, isError) {
        case (true, false):
            return Color(.textSubtle)
        case (_, true):
            return Color(.error)
        case (false, _):
            return Color(.textTertiary)
        }
    }
}

struct ErrorStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.body)
            .foregroundColor(Color(.error))
    }
}

struct WooNavigationBarStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .accentColor(Color(.accent)) // The color of bar button items in the navigation bar
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

    func largeTitleStyle() -> some View {
        self.modifier(LargeTitleStyle())
    }

    /// - Parameters:
    ///     - isEnabled: Whether the view is enabled (to apply specific styles for disabled view)
    ///     - isError: Whether the view shows error state.
    func footnoteStyle(isEnabled: Bool = true, isError: Bool = false) -> some View {
        self.modifier(FootnoteStyle(isEnabled: isEnabled, isError: isError))
    }

    func errorStyle() -> some View {
        self.modifier(ErrorStyle())
    }

    func wooNavigationBarStyle() -> some View {
        self.modifier(WooNavigationBarStyle())
    }
}
